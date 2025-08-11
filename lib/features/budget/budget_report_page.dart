import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../wallet/wallet_service.dart';

/// ===== 팔레트 & 데이터 모델 =====
class RColor {
  static const navy = Color(0xFF0D1B2A);
  static const sub  = Color(0xFF6B7280);
  static const ring = Color(0xFFEFF2F7);
}

class CategorySlice {
  final String name;
  final double value; // 금액(원)
  final Color color;
  const CategorySlice({required this.name, required this.value, required this.color});
}

/// ===== 월간 리포트(지갑 내역 기반) =====
class BudgetReportPage extends StatelessWidget {
  const BudgetReportPage({super.key});

  // 이번 달 키(YYYYMM)
  String _ym([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}';
  }

  // 카테고리 → 컬러 맵
  static const Map<String, Color> _catColor = {
    'MOBILITY': Color(0xFF3E63FF),
    'TRANSFER': Color(0xFF8B5CF6),
    'FOOD':     Color(0xFFF59E0B),
    'DEPOSIT':  Color(0xFF10B981),
    'WALLET_송금': Color(0xFF6366F1),
    'WITHDRAW': Color(0xFFEF4444),
    'ETC':      Color(0xFF94A3B8),
  };

  Color _colorFor(String name, int idx) {
    if (_catColor.containsKey(name)) return _catColor[name]!;
    // fallback 팔레트
    const fallbacks = [
      Color(0xFF60A5FA),
      Color(0xFF34D399),
      Color(0xFFF59E0B),
      Color(0xFFF472B6),
      Color(0xFF22D3EE),
      Color(0xFFA78BFA),
      Color(0xFFFB7185),
    ];
    return fallbacks[idx % fallbacks.length];
  }

  // 이번 달 지출(음수 amount)의 카테고리 합산
  List<CategorySlice> _buildSlices(List<Map<String, dynamic>> tx) {
    final nowKey = _ym();
    final Map<String, double> sums = {};

    for (final t in tx) {
      final amt = (t['amount'] as num?)?.toInt() ?? 0;
      if (amt >= 0) continue; // 지출만
      final created = (t['createdAt'] as String?) ?? '';
      final yyyymm = created.length >= 7 ? created.substring(0, 7).replaceAll('-', '') : '';
      if (yyyymm != nowKey) continue;

      final cat = (t['category'] as String?)?.trim();
      final name = (cat == null || cat.isEmpty) ? 'ETC' : cat;
      sums[name] = (sums[name] ?? 0) + (-amt); // 양수로 누적
    }

    final entries = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // 큰 금액 순

    return [
      for (int i = 0; i < entries.length; i++)
        CategorySlice(name: entries[i].key, value: entries[i].value, color: _colorFor(entries[i].key, i)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final period = DateTime(DateTime.now().year, DateTime.now().month, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Payments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        elevation: 0, toolbarHeight: 48, backgroundColor: Colors.white,
        actions: const [Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.notifications_none, size: 20))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: WalletService.txVN,
          builder: (_, tx, __) {
            final cats = _buildSlices(tx);
            final total = cats.fold<double>(0, (p, e) => p + e.value);
            final top = cats.isEmpty ? null : cats.first; // 정렬됨
            final daysInMonth = DateTime(period.year, period.month + 1, 0).day;
            final avg = total > 0 ? (total / daysInMonth).round() : 0;

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('소비 리포트(월간)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF223A7A))),
              const SizedBox(height: 10),

              // 월 표시
              Center(
                child: RichText(
                  text: TextSpan(style: const TextStyle(color: Colors.black, height: 1.1), children: [
                    TextSpan(text: '${period.year}년 ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    TextSpan(text: '${period.month}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    const TextSpan(text: ' 월', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),

              // 차트 + 레전드 / 데이터 없을 때 플레이스홀더
              Expanded(
                child: cats.isEmpty
                    ? const _EmptyState()
                    : Row(children: [
                  Expanded(
                    child: _AnimatedDonut(
                      cats: cats,
                      thickness: 24,
                      gapDeg: 6,
                      innerShadow: 4,
                      center: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(999),
                          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 8))],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _Legend(cats: cats, total: total),
                ]),
              ),

              const SizedBox(height: 10),

              // 하이라이트 & 통계
              if (cats.isNotEmpty) ...[
                _HighlightCard(
                  title: '이번 달 사용 1위 카테고리',
                  value: top!.name,
                  accent: top.color,
                ),
                const SizedBox(height: 8),
                _StatRows(totalAmount: total.toInt(), avgPerDay: avg, categoryCount: cats.length),
              ],
            ]);
          },
        ),
      ),
    );
  }
}

/// ===== Empty =====
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.pie_chart_outline_rounded, size: 48, color: RColor.sub),
        SizedBox(height: 8),
        Text('이번 달 지출 데이터가 없어요', style: TextStyle(color: RColor.sub)),
      ]),
    );
  }
}

/// ===== Legend =====
class _Legend extends StatelessWidget {
  final List<CategorySlice> cats;
  final double total;
  const _Legend({required this.cats, required this.total});

  String _pct(double v) => total == 0 ? '0%' : '${(v / total * 100).toStringAsFixed(0)}%';
  String _won(num v) {
    final s = v.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final r = s.length - i;
      b.write(s[i]);
      if (r > 1 && r % 3 == 1) b.write(',');
    }
    return '$b원';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final s in cats) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_pct(s.value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  Text('${s.name} · ${_won(s.value)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: RColor.sub, height: 1.2)),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// ===== Highlight =====
class _HighlightCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  const _HighlightCard({required this.title, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: accent.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Icon(Icons.star_rounded, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 11, color: RColor.sub, height: 1.3)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, height: 1.3)),
          ]),
        ),
      ]),
    );
  }
}

/// ===== Stats =====
class _StatRows extends StatelessWidget {
  final int totalAmount;
  final int avgPerDay;
  final int categoryCount;
  const _StatRows({required this.totalAmount, required this.avgPerDay, required this.categoryCount});

  String _won(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final r = s.length - i;
      b.write(s[i]);
      if (r > 1 && r % 3 == 1) b.write(',');
    }
    return '$b원';
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(k, style: const TextStyle(fontSize: 13, height: 1.4, color: RColor.sub))),
      Text(v, style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w800)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        _row('총 지출', _won(totalAmount)),
        const Divider(height: 22, color: Color(0xFFE5E7EB), thickness: 1),
        _row('1일 평균', _won(avgPerDay)),
        const Divider(height: 22, color: Color(0xFFE5E7EB), thickness: 1),
        _row('카테고리 수', '$categoryCount개'),
      ]),
    );
  }
}

/// ===== 커스텀 도넛(애니메이션) =====
class _AnimatedDonut extends StatelessWidget {
  final List<CategorySlice> cats;
  final double thickness, gapDeg, innerShadow;
  final Widget? center;
  const _AnimatedDonut({
    required this.cats,
    this.thickness = 24,
    this.gapDeg = 6,
    this.innerShadow = 4,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final total = cats.fold<double>(0, (p, e) => p + e.value);
    return AspectRatio(
      aspectRatio: 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(
          painter: _DonutPainter(
            slices: cats,
            total: total == 0 ? 1 : total,
            thickness: thickness,
            gap: gapDeg * math.pi / 180,
            start: -math.pi / 2,
            innerShadow: innerShadow,
            t: t,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategorySlice> slices;
  final double total, thickness, gap, start, innerShadow, t;
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.thickness,
    required this.gap,
    required this.start,
    required this.innerShadow,
    required this.t,
  });

  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(0, 0, s.width, s.height).deflate(thickness / 2 + 6);

    final bg = Paint()
      ..color = RColor.ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    c.drawArc(rect, 0, math.pi * 2, false, bg);

    if (innerShadow > 0) {
      final inner = Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 5);
      c.drawArc(rect, 0, math.pi * 2, false, inner);
    }

    var angle = start;
    for (final sItem in slices) {
      if (sItem.value <= 0) { angle += 0; continue; }
      final frac = (sItem.value / total).clamp(0.0, 1.0);
      final full = frac * (math.pi * 2);
      final sweep = (full * t) - gap;
      if (sweep <= 0) { angle += full; continue; }

      final shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.white], // shader는 색만 필요 — 아래서 stroke에 color 직접 쓸 수도 있음
      ).createShader(rect);

      final p = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = sItem.color;

      c.drawArc(rect, angle + gap / 2, sweep, false, p);
      angle += full;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) =>
      o.slices != slices ||
          o.total != total ||
          o.t != t ||
          o.thickness != thickness ||
          o.gap != gap ||
          o.start != start ||
          o.innerShadow != innerShadow;
}
