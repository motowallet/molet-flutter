import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 이동 단계
enum TripPhase { idle, paired, ready, moving, arrived, paying, paid, error }

/// 매칭된 차량 정보 (서버 포맷은 팀과 합의 필요)
class VehicleInfo {
  final String id;
  final String model;
  final String plate;
  final String color;
  final int? seats;
  final int? battery;        // %
  VehicleInfo({
    required this.id,
    required this.model,
    required this.plate,
    required this.color,
    this.seats,
    this.battery,
  });

  factory VehicleInfo.fromJson(Map m) => VehicleInfo(
    id: (m['id'] ?? '').toString(),
    model: (m['model'] ?? '').toString(),
    plate: (m['plate'] ?? '').toString(),
    color: (m['color'] ?? '').toString(),
    seats: (m['seats'] as num?)?.toInt(),
    battery: (m['battery'] as num?)?.toInt(),
  );
}

class TripSession extends ChangeNotifier {
  TripSession({
    required this.tripId,
    required this.wsUrl,
    this.token = '',
    this.demo = false,
  });

  final String tripId;
  final String wsUrl;
  final String token;
  final bool demo;

  TripPhase phase = TripPhase.idle;
  double progress = 0.0;         // 0~1
  String lastYolo = '';          // YOLO 이벤트 텍스트
  String? error;

  // 매칭된 차량 정보/ETA/거리 (있을 수도, 없을 수도)
  VehicleInfo? vehicle;
  int? etaSec;                   // 도착 예상(초)
  double? vehicleDistanceKm;     // 현재 차량까지 거리(km)

  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  int _fail = 0;
  bool _closed = false;

  /// 연결 시작: 데모면 시뮬레이터, 아니면 WebSocket
  Future<void> connect() async {
    _closed = false;
    if (demo || wsUrl.startsWith('mock://')) {
      _runDemo();
      return;
    }
    await _open();
  }

  /// 차량 호출(출발/도착 좌표 전달)
  void requestRide({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    if (demo || wsUrl.startsWith('mock://')) {
      phase = TripPhase.paired;
      notifyListeners();
      return;
    }
    _send({
      'type': 'REQUEST',
      'tripId': tripId,
      'from': {'lat': fromLat, 'lng': fromLng},
      'to': {'lat': toLat, 'lng': toLng},
    });
    phase = TripPhase.paired;
    notifyListeners();
  }

  /// 자원 정리
  Future<void> disposeAsync() async {
    _closed = true;
    _pingTimer?.cancel();
    await _sub?.cancel();
    await _ch?.sink.close();
  }

  // ================= DEMO =================
  void _runDemo() {
    // 데모에서도 차량 카드가 보이도록 샘플 세팅
    vehicle = VehicleInfo(
      id: 'V-001',
      model: 'Molet One',
      plate: '12가3456',
      color: '흰색',
      battery: 84,
    );
    etaSec = 180;               // 3분
    vehicleDistanceKm = 0.9;    // 0.9km
    phase = TripPhase.paired;
    notifyListeners();

    // 1초 뒤 READY
    Future.delayed(const Duration(seconds: 1), () {
      if (_closed) return;
      phase = TripPhase.ready;
      notifyListeners();
    });

    // 2초 뒤 MOVING + 진행률 시뮬
    Future.delayed(const Duration(seconds: 2), () {
      if (_closed) return;
      phase = TripPhase.moving;
      progress = 0;
      notifyListeners();

      int i = 0;
      Timer.periodic(const Duration(milliseconds: 200), (t) {
        if (_closed) { t.cancel(); return; }
        i++;
        progress = (i / 30).clamp(0.0, 1.0);
        lastYolo = (i % 9 == 0) ? 'pedestrian' : '';
        // ETA/거리도 조금씩 줄여보자(시각용)
        if (etaSec != null && etaSec! > 0) etaSec = (etaSec! - 6).clamp(0, 9999);
        if (vehicleDistanceKm != null && vehicleDistanceKm! > 0) {
          vehicleDistanceKm = (vehicleDistanceKm! - 0.03).clamp(0.0, 9999.0);
        }
        notifyListeners();

        if (i >= 30) {
          t.cancel();
          phase = TripPhase.arrived;
          progress = 1.0;
          notifyListeners();
        }
      });
    });
  }

  // ================= REAL WS =================
  Future<void> _open() async {
    _ch = WebSocketChannel.connect(Uri.parse(wsUrl));
    _sub = _ch!.stream.listen(_onMsg, onError: (e, _) => _onClosed(), onDone: _onClosed);
    _send({'type': 'HELLO', 'app': 'molet', 'tripId': tripId});
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _send({'type': 'PING', 'ts': DateTime.now().toIso8601String()});
    });
  }

  void _send(Map<String, dynamic> m) {
    try { _ch?.sink.add(jsonEncode(m)); } catch (_) {}
  }

  void _onMsg(dynamic raw) {
    Map<String, dynamic>? m;
    try { m = jsonDecode(raw as String) as Map<String, dynamic>; } catch (_) {}
    if (m == null) return;

    switch ((m['type'] ?? '').toString()) {
      case 'VEHICLE': // ← 서버가 매칭 직후 내려줄 예상 타입명 (팀 합의 필요)
      case 'MATCH':
        final info = (m['info'] as Map?) ?? const {};
        vehicle = VehicleInfo.fromJson(info);
        etaSec = (m['etaSec'] as num?)?.toInt();
        vehicleDistanceKm = (m['distanceKm'] as num?)?.toDouble();
        notifyListeners();
        break;

      case 'STATE':
        final v = (m['value'] as String?) ?? '';
        if (v == 'READY')   phase = TripPhase.ready;
        if (v == 'MOVING')  phase = TripPhase.moving;
        if (v == 'ARRIVED') phase = TripPhase.arrived;
        if (v == 'PAID')    phase = TripPhase.paid;
        notifyListeners();
        break;

      case 'PROGRESS':
        progress = ((m['pct'] ?? 0) as num).toDouble().clamp(0, 1);
        notifyListeners();
        break;

      case 'YOLO':
        lastYolo = (m['event'] ?? '').toString();
        notifyListeners();
        break;

      case 'ERROR':
        error = (m['reason'] ?? 'unknown').toString();
        phase  = TripPhase.error;
        notifyListeners();
        break;
    }
  }

  void _onClosed() {
    _pingTimer?.cancel();
    if (_closed || phase == TripPhase.paid || phase == TripPhase.error) return;

    _fail++;
    if (_fail > 3) {
      error = 'DISCONNECTED';
      phase = TripPhase.error;
      notifyListeners();
      return;
    }
    Future.delayed(Duration(milliseconds: 400 * _fail), () async {
      try { await _open(); _fail = 0; } catch (_) {}
    });
  }
}
