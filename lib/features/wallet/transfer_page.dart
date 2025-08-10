import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../wallet/amount_sheet.dart';
import '../wallet/success_page.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});
  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _search = TextEditingController();
  final _friends = List.generate(10, (i) => {'name': '이바보$i', 'address': '0xABCD...$i'});
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _friends.where((f) => f['name']!.toLowerCase().contains(_q.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('송금하기')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: '이름 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final f = filtered[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(f['name']!),
                  subtitle: Text(f['address']!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final amount = await showAmountSheet(context);
                    if (amount == null) return;

                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('송금하시겠습니까?'),
                        content: Text('${f['name']}에게 ${NumberFormat('#,###').format(amount)}원'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('아니요')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('네')),
                        ],
                      ),
                    );
                    if (ok != true) return;

                    await Future.delayed(const Duration(milliseconds: 400));

                    if (!mounted) return;
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuccessPage(
                          title: '송금이 완료되었습니다',
                          amount: amount,
                          toName: f['name']!,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    Navigator.pop(context, result);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
