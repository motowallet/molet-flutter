import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'waiting_page.dart';
import 'trip_flow.dart';

class MapSelectPage extends StatefulWidget {
  final String from, to;
  const MapSelectPage({super.key, this.from = '', this.to = ''});

  @override
  State<MapSelectPage> createState() => _MapSelectPageState();
}

class _MapSelectPageState extends State<MapSelectPage> {
  KakaoMapController? _controller;
  LatLng? _origin;
  LatLng? _dest;

  String? _originName;
  String? _destName;
  bool _loadingOrigin = false;
  bool _loadingDest = false;

  final LatLng _center = LatLng(37.5665, 126.9780);

  // ===== Kakao Local REST =====
  static const _restKey = String.fromEnvironment('KAKAO_REST_API_KEY');
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://dapi.kakao.com',
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    headers: {'Authorization': 'KakaoAK $_restKey'},
  ));

  Future<String> _reverseGeocode(LatLng p) async {
    try {
      final r = await _dio.get('/v2/local/geo/coord2address.json', queryParameters: {
        'x': p.longitude,
        'y': p.latitude,
      });
      final docs = (r.data?['documents'] as List?) ?? const [];
      if (docs.isEmpty) {
        return '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
      }
      final doc = docs.first as Map;
      final road = (doc['road_address'] as Map?) ?? const {};
      final addr = (doc['address'] as Map?) ?? const {};
      final building = (road['building_name'] ?? '').toString().trim();
      if (building.isNotEmpty) return building;
      final addressName = (road['address_name'] ?? addr['address_name'] ?? '').toString();
      if (addressName.isNotEmpty) return addressName;
      return '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
    } catch (_) {
      return '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
    }
  }

  // ===== 지도 콜백 =====
  void _onMapCreated(KakaoMapController c) => _controller = c;

  void _onMapTap(LatLng p) async {
    if (_origin == null) {
      setState(() {
        _origin = p;
        _originName = null;
        _loadingOrigin = true;
      });
      final name = await _reverseGeocode(p);
      if (!mounted) return;
      setState(() {
        _originName = name;
        _loadingOrigin = false;
      });
    } else if (_dest == null) {
      setState(() {
        _dest = p;
        _destName = null;
        _loadingDest = true;
      });
      final name = await _reverseGeocode(p);
      if (!mounted) return;
      setState(() {
        _destName = name;
        _loadingDest = false;
      });
    } else {
      setState(() {
        _origin = p; _dest = null;
        _originName = null; _destName = null;
        _loadingOrigin = true;
      });
      final name = await _reverseGeocode(p);
      if (!mounted) return;
      setState(() {
        _originName = name;
        _loadingOrigin = false;
      });
    }
  }

  // ===== 거리/시간/요금(간단 추정 – 추측입니다) =====
  double _deg2rad(double d) => d * math.pi / 180.0;
  double _distKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final la1 = _deg2rad(a.latitude), la2 = _deg2rad(b.latitude);
    final h = math.sin(dLat/2)*math.sin(dLat/2) +
        math.cos(la1)*math.cos(la2)*math.sin(dLon/2)*math.sin(dLon/2);
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1-h));
  }
  int _mins(double km) => (km / 24.0 * 60).ceil(); // 24km/h 가정
  int _fare(double km) {
    const base = 3000, baseKm = 2.0, perKm = 1000;
    if (km <= baseKm) return base;
    return base + ((km - baseKm) * perKm).ceil();
  }
  String _won(int v) {
    final s = v.toString(); final b = StringBuffer();
    for (int i=0;i<s.length;i++){final r=s.length-i; b.write(s[i]); if(r>1&&r%3==1)b.write(',');}
    return '$b원';
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (_origin != null) Marker(markerId: 'origin', latLng: _origin!),
      if (_dest != null)   Marker(markerId: 'dest',   latLng: _dest!),
    ];
    final hasBoth = _origin != null && _dest != null;
    final km = hasBoth ? _distKm(_origin!, _dest!) : 0.0;
    final est = hasBoth ? _fare(km) : 0; // ← 추가: 예상요금 계산

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobility'),
        actions: [
          IconButton(
            tooltip: '초기화',
            onPressed: () => setState(() {
              _origin = null; _dest = null;
              _originName = null; _destName = null;
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: KakaoMap(
                  center: _center,
                  onMapCreated: _onMapCreated,
                  onMapTap: _onMapTap,
                  markers: markers,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pill(
                  Icons.trip_origin,
                  _origin == null
                      ? '지도를 탭해 출발지 선택'
                      : _loadingOrigin
                      ? '출발지 이름 조회 중...'
                      : '출발지: ${_originName!}',
                ),
                const SizedBox(height: 8),
                _pill(
                  Icons.flag,
                  _dest == null
                      ? '지도를 탭해 도착지 선택'
                      : _loadingDest
                      ? '도착지 이름 조회 중...'
                      : '도착지: ${_destName!}',
                ),
                const SizedBox(height: 8),
                _pill(
                  Icons.directions_car,
                  hasBoth
                      ? '거리 ${km.toStringAsFixed(2)}km · 예상 ${_mins(km)}분 · 요금 약 ${_won(est)}'
                      : '두 지점 선택 후 요금/시간 표시',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.directions_car_filled),
                  label: const Text('차량 호출'),
                  onPressed: hasBoth ? () {
                    // WS URL & 데모 여부
                    final wsEnv = const String.fromEnvironment('VEHICLE_WS_URL');
                    final useDemo = wsEnv.isEmpty;
                    final wsUrl   = wsEnv.isEmpty ? 'ws://192.168.4.1:8765/trip' : wsEnv;

                    // 세션 생성
                    final session = TripSession(
                      tripId: DateTime.now().millisecondsSinceEpoch.toString(),
                      wsUrl: wsUrl,
                      demo: useDemo,
                    );

                    // ✅ estimate 전달
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WaitingPage(
                          session: session,
                          origin: _origin!, dest: _dest!,
                          estimate: est, // ← 여기!
                        ),
                      ),
                    );
                  } : null,
                ),
                const SizedBox(height: 6),
                const Text(
                  '장소 이름은 카카오 Local API로 조회합니다. 네트워크 상태에 따라 지연될 수 있어요.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData i, String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
    child: Row(children:[Icon(i, size:18), const SizedBox(width:8), Expanded(child: Text(t))]),
  );
}
