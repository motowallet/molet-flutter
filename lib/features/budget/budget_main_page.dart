import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'budget_limit_page.dart';
import 'budget_usage_page.dart';
import 'budget_report_page.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          '예산 관리',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), // ↓ 작게
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0B1220), const Color(0xFF141A2A)]
                : [const Color(0xFFF6F8FC), const Color(0xFFEFF3FA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), // ↓ 살짝 컴팩트
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _MenuTile(
                      title: '월별 예산 설정',
                      subtitle: '한도 설정',
                      icon: Icons.tune,
                      onTap: () => _go(context, const BudgetLimitPage()),
                    ),
                    const SizedBox(height: 14),
                    _MenuTile(
                      title: '예산 사용률 확인',
                      subtitle: '이번 달 진행률 보기',
                      icon: Icons.speed,
                      onTap: () => _go(context, const BudgetUsagePage()),
                    ),
                    const SizedBox(height: 14),
                    _MenuTile(
                      title: '소비 리포트 분석',
                      subtitle: '카테고리·추세 리포트',
                      icon: Icons.pie_chart_rounded,
                      onTap: () => _go(context, const BudgetReportPage()),
                    ),
                    const Spacer(),
                    _TipBanner(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, .03), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1D2436) : Colors.white;
    final border = isDark ? const Color(0xFF2A3246) : const Color(0x11000000);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      tween: Tween(begin: 1, end: _pressed ? 0.98 : 1),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Material(
        color: baseColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // ↓ 여백 축소
            child: Row(
              children: [
                Container(
                  width: 44, // ↓ 아이콘 박스 축소
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.12),
                        theme.colorScheme.primary.withOpacity(0.04),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(widget.icon, size: 28, color: theme.colorScheme.primary), // ↓ 아이콘 크기
                  ),
                ),
                const SizedBox(width: 16), // ↓ 간격 축소
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 더 작게
                      Text(
                        widget.title,
                        style: theme.textTheme.titleSmall?.copyWith( // ← titleSmall
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.2,
                        ),
                      ),
                      const SizedBox(height: 6), // ↓ 간격 축소
                      // 부제 더 작게
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith( // ← bodySmall
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 24), // ↓ 크기 축소
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // ↓ 여백 축소
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101727) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18), // ↓ 아이콘 축소
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'TIP: 리포트에서 지난달 대비 소비 변화도 확인해보세요.',
              style: theme.textTheme.bodySmall?.copyWith( // ← bodySmall
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
