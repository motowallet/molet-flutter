import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'amount_sheet.dart';
import 'success_page.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});
  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _search = TextEditingController();
  final _friends = List.generate(10, (i) => {'name': '이가나$i', 'address': '0x1234...$i'});
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _friends.where((f) => f['name']!.toLowerCase().contains(_q.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('요청하기')),
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
                        title: const Text('요청하시겠습니까?'),
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
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SuccessPage(title: '요청이 완료되었습니다')),
                    );
                    if (!mounted) return;
                    Navigator.pop(context); // 변경 없음
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
