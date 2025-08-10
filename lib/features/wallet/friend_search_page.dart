import 'package:flutter/material.dart';
import 'request_page.dart';
import 'transfer_page.dart';

class FriendSearchPage extends StatefulWidget {
  final String initialQuery;
  const FriendSearchPage({super.key, this.initialQuery = ''});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initialQuery);
  final _all = List.generate(12, (i) => {'name': '이가나$i', 'address': '0xABCD...$i'});

  @override
  Widget build(BuildContext context) {
    final q = _ctrl.text.trim().toLowerCase();
    final list = _all.where((e) => e['name']!.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('친구 찾기')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '이름 또는 주소',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final f = list[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(f['name']!),
                  subtitle: Text(f['address']!),
                  trailing: Wrap(spacing: 8, children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferPage()));
                      },
                      child: const Text('송금'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestPage()));
                      },
                      child: const Text('요청'),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
