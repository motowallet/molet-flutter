import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BudgetLimitPage extends StatefulWidget {
  const BudgetLimitPage({super.key});
  @override
  State<BudgetLimitPage> createState() => _BudgetLimitPageState();
}

class _BudgetLimitPageState extends State<BudgetLimitPage> {
  final _won = NumberFormat('#,###');
  int _limit = 20000000;

  String _monthLabel() {
    final n = DateTime.now();
    return '${n.year}.${n.month.toString().padLeft(2, '0')}';
  }

  int _parse(String t) {
    final s = t.replaceAll(RegExp(r'[^0-9]'), '');
    return s.isEmpty ? 0 : int.parse(s);
  }

  Widget _chip(String label, VoidCallback onTap, {bool outline = false}) =>
      outline
          ? OutlinedButton(onPressed: onTap, child: Text(label))
          : FilledButton.tonal(onPressed: onTap, child: Text(label));

  Future<int?> _showLimitSheet() async {
    final c = TextEditingController(text: _won.format(_limit));
    final focus = FocusNode();
    void fmt() {
      final v = _won.format(_parse(c.text));
      c.value = TextEditingValue(
          text: v, selection: TextSelection.collapsed(offset: v.length));
    }

    final presets = [100000, 500000, 1000000, 5000000, 10000000];

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final kb = MediaQuery
            .of(ctx)
            .viewInsets
            .bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + kb),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2))),
                ),
                const Text('예산 한도 수정', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextField(
                  controller: c,
                  focusNode: focus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => fmt(),
                  decoration: const InputDecoration(
                    hintText: '금액을 입력하세요',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: '원',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in presets)
                    _chip('${_won.format(p)}원', () {
                      c.text = _won.format(_parse(c.text) + p);
                      fmt();
                    }),
                  _chip('초기화', () {
                    c.text = '0';
                    fmt();
                    FocusScope.of(ctx).requestFocus(focus);
                  }, outline: true),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final v = _parse(c.text);
                        if (v <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('1원 이상 입력해주세요.')));
                          return;
                        }
                        Navigator.pop(ctx, v);
                      },
                      child: const Text('저장'),
                    ),
                  ),
                ]),
              ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0D1B2A);
    return Scaffold(
      appBar: AppBar(title: const Text('월별 예산 설정')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final changed = await _showLimitSheet();
            if (!mounted) return;
            if (changed != null && changed > 0) {
              setState(() => _limit = changed);
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                  const SnackBar(content: Text('예산 한도가 저장되었습니다.')));
            }
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('한도 수정'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // 예산 카드
          Container(
            padding: const EdgeInsets.all(50),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [navy, Color(0xFF1B263B)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.savings_outlined, color: Colors.white),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('이번 달 예산 한도', style: TextStyle(color: Colors
                      .white70, fontSize: 18)),
                  Text('${_won.format(_limit)}원',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              Text(_monthLabel(), style: const TextStyle(color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 20),
          // 설명 박스 - 각진
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              border: Border.all(color: const Color(0xFFE6E8EC)),
              borderRadius: BorderRadius.zero,
            ),
            child: const Text(
              '예산 한도는 월 단위로 적용됩니다. 예산을 수정하면 이번 달부터 새로운 한도가 반영됩니다.',
              style: TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
            ),
          ),
        ]),
      ),
    );
  }
}

