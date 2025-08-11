import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🐹 PlusPet: 탭하면 쑥스러워하는 마스코트
class PlusPet extends StatefulWidget {
  const PlusPet({super.key, this.size = 88, this.emoji = '🪙'});
  final double size;
  final String emoji;

  @override
  State<PlusPet> createState() => _PlusPetState();
}

class _PlusPetState extends State<PlusPet> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  bool _shy = false;

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _shy = !_shy);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_shy ? '히히 🙈' : '안녕! 👋'),
              duration: const Duration(milliseconds: 700)),
        );
      },
      child: AnimatedBuilder(
        animation: t,
        builder: (_, __) {
          final hop = (math.sin(t.value * math.pi * 2) + 1) / 2 * 6; // 0~6
          final squish = 1 - (t.value - .5).abs() * .06;              // 0.94~1
          return Transform.translate(
            offset: Offset(0, -hop),
            child: Transform.scale(
              scale: squish,
              child: Container(
                width: widget.size, height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(widget.size),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
                  border: Border.all(color: const Color(0xFFE6E8EC)),
                ),
                alignment: Alignment.center,
                child: Text(_shy ? '🙈' : widget.emoji,
                    style: TextStyle(fontSize: widget.size * .45)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🥠 오늘의 라벨 스티커(탭하면 문구 바뀜)
class FortuneSticker extends StatefulWidget {
  const FortuneSticker({super.key});
  @override
  State<FortuneSticker> createState() => _FortuneStickerState();
}
class _FortuneStickerState extends State<FortuneSticker> {
  final _quotes = const [
    '오늘은 복권 말고 밥 먹기 🍙',
    '지갑은 가볍게, 마음은 무겁게(?!) 🤔',
    '커피 쿠폰… 언젠가 쓸 그 날 ☕️',
    '앗! 돈이 나를 스쳤다 💸',
    '절약은 내일부터! (항상 내일) 🐌',
  ];
  late String _q = _quotes[DateTime.now().millisecondsSinceEpoch % _quotes.length];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _q = _quotes[(_quotes.indexOf(_q) + 1) % _quotes.length]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          border: Border.all(color: const Color(0xFFFFE2A7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🥠', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(_q, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// 🪙 플러스 코인: 눌러도 아무 일 없음(회전 + 햅틱 + 토스트)
class PlusCoin extends StatefulWidget {
  const PlusCoin({super.key, this.size = 64});
  final double size;

  @override
  State<PlusCoin> createState() => _PlusCoinState();
}

class _PlusCoinState extends State<PlusCoin> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _turns += 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('플러스 코인 +1 (구경용)'), duration: Duration(milliseconds: 600)),
        );
      },
      child: AnimatedRotation(
        turns: _turns,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primary.withOpacity(.95), primary],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: const Text('P', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

/// 🔖 귀여운 배지 3종(지갑 이름/잔액으로 랜덤 느낌)
class PlusBadges extends StatelessWidget {
  const PlusBadges({super.key, required this.walletName, required this.balance});
  final String walletName;
  final int balance;

  int _hash(String s) => s.runes.fold(0, (p, e) => (p * 31 + e) & 0x7fffffff);

  @override
  Widget build(BuildContext context) {
    final lvl = (_hash(walletName) % 9) + 1;
    final lucky = (balance % 9) + 1;
    final seed = walletName.isEmpty ? 'PL' : walletName.substring(0, walletName.length.clamp(0, 2)).toUpperCase();

    Widget chip(String label, String value, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text('$label $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip('LVL', '$lvl', Icons.bolt_rounded),
        const SizedBox(width: 8),
        chip('Lucky', '$lucky', Icons.auto_awesome_rounded),
        const SizedBox(width: 8),
        chip('Seed', seed, Icons.tag_rounded),
      ],
    );
  }
}
