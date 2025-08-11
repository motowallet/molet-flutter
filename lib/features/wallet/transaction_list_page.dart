import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../wallet/wallet_service.dart';

class TransactionListPage extends StatefulWidget {
  final String initialFilter; // 'all' | 'payment' | 'deposit' | 'withdraw'
  const TransactionListPage({
    super.key,
    this.initialFilter = 'all',
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late String _filter;
  final _won = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('거래 내역')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('전체', 'all'),
                    _chip('결제', 'payment'),
                    _chip('입금', 'deposit'),
                    _chip('출금', 'withdraw'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1)

            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: WalletService.txVN,
                builder: (context, txs, _) {
                  final items = txs.where((e) {
                    final t = (e['type'] ?? '').toString();
                    return _filter == 'all' ? true : t == _filter;
                  }).toList();

                  // 최신순
                  items.sort((a, b) {
                    final da = (a['createdAt'] ?? '').toString();
                    final db = (b['createdAt'] ?? '').toString();
                    return db.compareTo(da);
                  });

                  if (items.isEmpty) {
                    return const Center(
                      child: Text('내역이 없습니다', style: TextStyle(color: Colors.black54)),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final title = (it['title'] ?? '').toString();
                      final date  = (it['createdAt'] ?? '').toString();
                      final type  = (it['type'] ?? '').toString();
                      final num rawAmt = (it['amount'] is num) ? it['amount'] as num : 0;
                      final amt = rawAmt.toInt();
                      final isIncome = type == 'deposit';
                      final color = isIncome ? Colors.green : Colors.redAccent;

                      return ListTile(
                        title: Text(title.isEmpty ? '(제목 없음)' : title),
                        subtitle: Text(date),
                        leading: Icon(
                          isIncome ? Icons.south_west : Icons.north_east,
                          size: 20, color: color,
                        ),
                        trailing: Text(
                          '${amt < 0 ? '-' : '+'}${_won.format(amt.abs())}원',
                          style: TextStyle(fontWeight: FontWeight.w700, color: color),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
