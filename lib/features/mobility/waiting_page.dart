import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // LatLng
import 'trip_flow.dart';
import '../wallet/wallet_page.dart';
import '../wallet/wallet_service.dart';
import 'qr_scan_page.dart';

class WaitingPage extends StatefulWidget {
  final TripSession session;
  final LatLng origin;
  final LatLng dest;

  /// (선택) 예상 요금. QR에 금액이 없을 때 fallback
  final int? estimate;

  const WaitingPage({
    super.key,
    required this.session,
    required this.origin,
    required this.dest,
    this.estimate,
  });

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  // 개발용: 테스트 버튼 노출 플래그
  static const showQuickConfirm =
  bool.fromEnvironment('SHOW_QUICK_CONFIRM', defaultValue: false);

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onUpdate);
    _start();
  }

  Future<void> _start() async {
    await widget.session.connect(); // WS 연결(또는 데모 시작)
    widget.session.requestRide(
      fromLat: widget.origin.latitude,
      fromLng: widget.origin.longitude,
      toLat: widget.dest.latitude,
      toLng: widget.dest.longitude,
    );
  }

  @override
  void dispose() {
    widget.session.removeListener(_onUpdate);
    widget.session.disposeAsync();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = widget.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobility'),
        actions: [
          IconButton(
            tooltip: '호출 취소',
            icon: const Icon(Icons.close),
            onPressed: () async {
              await widget.session.disposeAsync();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- 차량 카드 ---
                if (s.vehicle != null) _vehicleCard(s) else _vehiclePlaceholder(),
                const SizedBox(height: 16),

                // --- 진행 링 + 상태 텍스트 ---
                SizedBox(
                  width: 160, height: 160,
                  child: CircularProgressIndicator(
                    strokeWidth: 10,
                    value: s.phase == TripPhase.moving ? s.progress : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(_label(s.phase, s.lastYolo)),
                if (s.phase == TripPhase.moving)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('진행률 ${(s.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.black54)),
                  ),

                const SizedBox(height: 20),

                // --- 도착 시: QR 결제 ---
                if (s.phase == TripPhase.arrived)
                  Column(
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('QR로 결제하기'),
                        onPressed: () async {
                          // 1) 차량 QR 스캔(원문)
                          final raw = await Navigator.push<String?>(
                            context,
                            MaterialPageRoute(builder: (_) => const QrScanPage()),
                          );
                          if (!mounted || raw == null) return;

                          // 2) QR에서 금액 파싱(확실하지 않음: 포맷 팀 합의 필요)
                          final amt = _parseAmountFromQr(raw) ?? widget.estimate ?? 0;

                          // 3) 결제 확인 시트 → 결제
                          final paid = await _confirmAndPay(initialAmount: amt, tripId: s.tripId);
                          if (!mounted || paid != true) return;

                          // 4) 완료 처리
                          s.phase = TripPhase.paid;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const WalletPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('차량에 표시된 QR을 스캔해 결제하세요.',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),

                      // --- (개발용) QR 생략하고 바로 결제 확인 시트 띄우기 ---
                      if (kDebugMode || showQuickConfirm) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            final paid = await _confirmAndPay(
                              initialAmount: widget.estimate ?? 0,
                              tripId: s.tripId,
                            );
                            if (!mounted || paid != true) return;
                            s.phase = TripPhase.paid;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const WalletPage()),
                            );
                          },
                          child: const Text('결제 확인만 보기(개발용)'),
                        ),
                      ],
                    ],
                  ),

                // --- 에러 표시 ---
                if (s.phase == TripPhase.error && s.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(s.error!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== UI helpers =====
  Widget _vehicleCard(TripSession s) {
    final v = s.vehicle!;
    final etaMin = s.etaSec != null ? (s.etaSec! / 60).ceil() : null;
    final dist = s.vehicleDistanceKm;
    final meta = <String>[
      if (v.plate.isNotEmpty) '차량번호 ${v.plate}',
      if (dist != null) '${dist.toStringAsFixed(1)}km',
      if (etaMin != null) 'ETA ${etaMin}분',
      if (v.battery != null) '배터리 ${v.battery}%',
    ].join(' · ');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.directions_car_filled),
        title: Text('${v.model} · ${v.color}'),
        subtitle: meta.isEmpty ? null : Text(meta),
      ),
    );
  }

  Widget _vehiclePlaceholder() => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: const ListTile(
      leading: Icon(Icons.directions_car_filled),
      title: Text('차량 배정 중...'),
      subtitle: Text('잠시만 기다려 주세요'),
    ),
  );

  String _label(TripPhase p, String yolo) {
    switch (p) {
      case TripPhase.paired: return '차량 호출 중...';
      case TripPhase.ready:  return '차량 준비 중';
      case TripPhase.moving: return yolo.isEmpty ? '이동 중...' : '이동 중 · $yolo 감지';
      case TripPhase.arrived:return '도착했습니다. 결제를 진행해주세요.';
      case TripPhase.paid:   return '결제 완료';
      case TripPhase.paying: return '결제 진행 중';
      case TripPhase.error:  return '연결 오류';
      default:               return '연결 중...';
    }
  }

  // ===== 결제(간단 시트) =====
  Future<bool?> _confirmAndPay({int? initialAmount, String? tripId}) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        bool busy = false;
        String? msg;
        final ctrl = TextEditingController(text: initialAmount?.toString() ?? '');
        int? amount = initialAmount;

        return StatefulBuilder(builder: (ctx, setSheet) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: FutureBuilder<int>(
                future: WalletService.balance(),
                builder: (ctx, snap) {
                  final bal = snap.data;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('결제 확인', style: Theme.of(ctx).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (amount == null)
                        Row(
                          children: [
                            const Text('결제 금액'),
                            const Spacer(),
                            SizedBox(
                              width: 160,
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.end,
                                decoration: const InputDecoration(hintText: '금액 입력'),
                                onChanged: (_) {
                                  amount = int.tryParse(ctrl.text.replaceAll(',', ''));
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        _row('결제 금액', _won(amount!)),
                      const SizedBox(height: 6),
                      _row('내 잔액', bal == null ? '불러오는 중...' : _won(bal)),
                      if (tripId != null) ...[
                        const SizedBox(height: 6),
                        _row('트립 ID', tripId),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: (busy || bal == null) ? null : () async {
                          final a = amount ?? int.tryParse(ctrl.text.replaceAll(',', ''));
                          if (a == null || a <= 0) {
                            setSheet(() => msg = '유효한 금액을 입력해 주세요.');
                            return;
                          }
                          setSheet(() { busy = true; msg = null; });
                          final ok = await WalletService.pay(a);
                          setSheet(() => busy = false);
                          if (!mounted) return;
                          ok ? Navigator.pop(ctx, true)
                              : setSheet(() => msg = '잔액 부족');
                        },
                        child: busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('결제하기'),
                      ),
                      if (msg != null) ...[
                        const SizedBox(height: 8),
                        Text(msg!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 4),
                    ],
                  );
                },
              ),
            ),
          );
        });
      },
    );
  }

  // ===== 유틸 =====
  Widget _row(String k, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
  );

  String _won(int v) {
    final s = v.toString(); final b = StringBuffer();
    for (int i=0;i<s.length;i++){final r=s.length-i; b.write(s[i]); if(r>1&&r%3==1)b.write(',');}
    return '$b원';
  }

  int? _parseAmountFromQr(String raw) {
    // 확실하지 않음: QR 포맷 팀 합의 필요. 임시 키(amt/amount) 및 텍스트 금액 파싱.
    try {
      final u = Uri.parse(raw);
      final a = u.queryParameters['amt'] ?? u.queryParameters['amount'];
      if (a != null) return int.tryParse(a);
    } catch (_) {}
    final m = RegExp(r'(\d{3,})\s*원?').firstMatch(raw.replaceAll(',', ''));
    if (m != null) return int.tryParse(m.group(1)!);
    return null;
  }
}
