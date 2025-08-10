import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionListPage extends StatefulWidget {
  final List<Map<String, dynamic>> allTx;
  final String initialFilter; // 'all' | 'payment' | 'deposit' | 'withdraw'
  const TransactionListPage({
    super.key,
    required this.allTx,
    this.initialFilter = 'all',
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late String _filter = widget.initialFilter;
  final _won = NumberFormat('#,###');

  List<Map<String, dynamic>> get _list =>
      widget.allTx.where((e) => _filter == 'all' ? true : e['type'] == _filter).toList();

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
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final it = _list[i];
                  final amt = it['amount'] as int;
                  return ListTile(
                    title: Text(it['title'] as String),
                    subtitle: Text(it['createdAt'] as String),
                    leading: Icon(
                      it['type'] == 'deposit'
                          ? Icons.south_west
                          : Icons.north_east,
                      size: 20,
                      color: it['type'] == 'deposit' ? Colors.green : Colors.redAccent,
                    ),
                    trailing: Text(
                      '${amt < 0 ? '-' : '+'}${_won.format(amt.abs())}원',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: amt < 0 ? Colors.redAccent : Colors.green,
                      ),
                    ),
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
