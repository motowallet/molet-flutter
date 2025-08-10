import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// ===== 데이터 모델 =====
class CategorySlice {
  final String name;
  final double value; // 퍼센트든 금액이든 OK (합계로 비율 자동계산)
  final Color color;
  const CategorySlice({required this.name, required this.value, required this.color});
}

class ReportData {
  final DateTime period;          // 보고 기간(예: 2025-05-01)
  final List<CategorySlice> cats; // 카테고리 목록
  final int? totalAmount;         // 총 지출(원). 없으면 null 허용
  const ReportData({required this.period, required this.cats, this.totalAmount});
}

/// ===== 팔레트 =====
class RColor {
  static const navy = Color(0xFF0D1B2A);
  static const sub  = Color(0xFF6B7280);
  static const ring = Color(0xFFEFF2F7);
}

/// ===== 월간 리포트 페이지(주간 제거, 무상태) =====
class BudgetReportPage extends StatelessWidget {
  const BudgetReportPage({super.key, this.data});
  final ReportData? data; // ← 백엔드 데이터 주입

  ReportData get _data {
    // 샘플(백엔드 연결 시 이 블록 제거하고 data만 사용)
    final sample = ReportData(
      period: DateTime(2025, 5, 1),
      totalAmount: 1234567,
      cats: const [
        CategorySlice(name: 'WALLET_송금', value: 58, color: Color(0xFF3E63FF)),
        CategorySlice(name: 'FOOD',       value: 28, color: Color(0xFF8B5CF6)),
        CategorySlice(name: 'MOTO',       value: 14, color: Color(0xFFF59E0B)),
      ],
    );
    return data ?? sample;
  }

  @override
  Widget build(BuildContext context) {
    final cats = _data.cats;
    final totalVal = cats.fold<double>(0, (p, e) => p + e.value);
    final top = cats.isEmpty ? null : cats.reduce((a, b) => a.value >= b.value ? a : b);
    final period = _data.period;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0, toolbarHeight: 52, backgroundColor: Colors.white,
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.notifications_none))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('소비 리포트(월간)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF223A7A))),
          const SizedBox(height: 16),

          // 월 표시
          Center(
            child: RichText(
              text: TextSpan(style: const TextStyle(color: Colors.black, height: 1.2), children: [
                TextSpan(text: '${period.year}년 ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                TextSpan(text: '${period.month}',  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const TextSpan(text: ' 월',        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 10),

          // 차트 + 레전드
          Expanded(
            child: Row(children: [
              Expanded(
                child: _AnimatedDonut(
                  cats: cats,
                  thickness: 30,
                  gapDeg: 8,
                  innerShadow: 6,
                  center: Container(
                    width: 92, height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(999),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10))],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              _legend(cats, totalVal),
            ]),
          ),

          const SizedBox(height: 12),

          // 하이라이트 카드
          _highlightCard(
            title: '이번 달 사용 1위 카테고리',
            value: top?.name ?? '—',
            accent: top?.color ?? RColor.navy,
          ),
          const SizedBox(height: 10),

          // 통계 3줄 (총지출 / 1일 평균 / 카테고리 수)
          _statRows(
            totalAmount: _data.totalAmount,
            daysInMonth: DateTime(period.year, period.month + 1, 0).day,
            categoryCount: cats.length,
          ),
        ]),
      ),
    );
  }

  // ===== helpers =====

  Widget _legend(List<CategorySlice> data, double total) {
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final s in data) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${total == 0 ? 0 : (s.value / total * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: RColor.sub)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _highlightCard({required String title, required String value, required Color accent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: accent.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Icon(Icons.star_rounded, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, color: RColor.sub, height: 1.4)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _statRows({int? totalAmount, required int daysInMonth, required int categoryCount}) {
    String won(int? v) {
      if (v == null) return '—';
      final s = v.toString();
      final buf = StringBuffer();
      int cnt = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        buf.write(s[i]);
        cnt++;
        if (cnt % 3 == 0 && i != 0) buf.write(',');
      }
      return buf.toString().split('').reversed.join();
    }

    final avg = (totalAmount == null) ? null : (totalAmount / daysInMonth).round();

    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(k, style: const TextStyle(fontSize: 15, height: 1.5, color: RColor.sub))),
        Text(v, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w800)),
      ]),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        row('총 지출', totalAmount == null ? '—' : '${won(totalAmount)}원'),
        const Divider(height: 26, color: Color(0xFFE5E7EB), thickness: 1),
        row('1일 평균', avg == null ? '—' : '${won(avg)}원'),
        const Divider(height: 26, color: Color(0xFFE5E7EB), thickness: 1),
        row('카테고리 수', '$categoryCount개'),
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
    this.thickness = 28,
    this.gapDeg = 7,
    this.innerShadow = 6,
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
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 6);
      c.drawArc(rect, 0, math.pi * 2, false, inner);
    }

    var angle = start;
    for (final sItem in slices) {
      if (sItem.value <= 0) {
        angle += 0;
        continue;
      }
      final frac = (sItem.value / total).clamp(0.0, 1.0);
      final full = frac * (math.pi * 2);
      final sweep = (full * t) - gap;
      if (sweep <= 0) {
        angle += full;
        continue;
      }

      final shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [sItem.color.withOpacity(.95), sItem.color],
      ).createShader(rect);

      final p = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

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
