import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetUsagePage extends StatefulWidget {
  const BudgetUsagePage({super.key});

  @override
  State<BudgetUsagePage> createState() => _BudgetUsagePageState();
}

class _BudgetUsagePageState extends State<BudgetUsagePage> {
  bool _loading = true;
  int _total = 0; // 총 예산
  int _used = 0;  // 이번 달 사용액

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _ym([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sp = await SharedPreferences.getInstance();
    final ym = _ym();

    // BudgetLimitPage에서 저장해야 하는 키:
    //   'budget_limit_YYYYMM'  (총 예산)
    // WalletService.pay()/transfer()에서 누적해 둔 키:
    //   'budget_used_YYYYMM'   (이번 달 사용액)
    final total = sp.getInt('budget_limit_$ym') ?? 300000; // 기본값 30만
    final used  = sp.getInt('budget_used_$ym')  ?? 0;

    if (!mounted) return;
    setState(() {
      _total = total;
      _used  = used.clamp(0, total); // total 없을 땐 그대로 표시하고 싶으면 이 줄 수정
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('예산 사용률 확인'), toolbarHeight: 48),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final won = NumberFormat('#,###');
    final total = _total;
    final used = _used;
    final remaining = (total > 0) ? (total - used).clamp(0, total) : 0;
    final usage = (total > 0) ? (used / total).clamp(0.0, 1.0) : 0.0;
    final danger = usage >= .8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('예산 사용률 확인'),
        toolbarHeight: 48,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // 메인 카드
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEFF4FF), Color(0xFFF9FAFB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, 8)),
                      ],
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: Colors.white.withOpacity(.25)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: usage),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => CustomPaint(
                              painter: _PrettySemiGaugePainter(
                                progress: v,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6EA8FF), Color(0xFF3E63FF)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Center(
                                child: TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: used),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOut,
                                  builder: (_, val, __) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${won.format(val)}원',
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Text('총 예산 ${won.format(total)}원',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        _infoRow(
                          icon: Icons.trending_up,
                          iconBg: const Color(0xFFFFF3F0),
                          iconColor: const Color(0xFFEF4444),
                          label: '사용',
                          value: '${won.format(used)}원',
                        ),
                        const Divider(height: 25, thickness: 1, color: Color(0xFFE5E7EB)),

                        _infoRow(
                          icon: Icons.savings_outlined,
                          iconBg: const Color(0xFFEFFBF5),
                          iconColor: const Color(0xFF10B981),
                          label: '잔여',
                          value: '${won.format(remaining)}원',
                        ),
                        const Divider(height: 25, thickness: 1, color: Color(0xFFE5E7EB)),

                        _infoRow(
                          icon: Icons.percent,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF3B82F6),
                          label: '사용률',
                          value: '${(usage * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 경고/안내 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: danger ? const Color(0xFFFFF3F3) : const Color(0xFFF0FDF4),
                border: Border.all(color: danger ? const Color(0xFFF4B4B4) : const Color(0xFFA7F3D0)),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(
                    danger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 20,
                    color: danger ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      danger ? '주의! 예산의 80% 이상을 사용했습니다.' : '좋아요! 아직 예산에 여유가 있어요.',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('돌아가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PrettySemiGaugePainter extends CustomPainter {
  final double progress;
  final Gradient gradient;
  _PrettySemiGaugePainter({required this.progress, required this.gradient});

  @override
  void paint(Canvas c, Size s) {
    const stroke = 18.0;
    final rect = Rect.fromLTWH(stroke, stroke, s.width - stroke * 2, s.height * 2 - stroke * 2);
    const start = math.pi, sweep = math.pi;

    final bg = Paint()
      ..color = const Color(0xFFE8EDF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    c.drawArc(rect, start, sweep, false, bg);

    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    final shadow = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    c.drawArc(rect, start, sweep * p, false, shadow);

    final fg = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    c.drawArc(rect, start, sweep * p, false, fg);

    final ang = start + sweep * p;
    final cx = rect.center.dx + rect.width / 2 * math.cos(ang);
    final cy = rect.center.dy + rect.height / 2 * math.sin(ang);
    c.drawCircle(Offset(cx, cy), stroke * .36, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant _PrettySemiGaugePainter o) =>
      o.progress != progress || o.gradient != gradient;
}
