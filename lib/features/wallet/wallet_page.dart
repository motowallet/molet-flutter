import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'friend_search_page.dart';
import 'request_page.dart';
import 'transfer_page.dart';
import 'transaction_list_page.dart';
import 'card_container.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String _filter = 'all'; // all|payment|deposit|withdraw
  final _won = NumberFormat('#,###');

  final _friendSearch = TextEditingController();

  // TODO: 서버 연동
  final _address = '0xA1b2...9F';
  int _balance = 9876543;

  final List<Map<String, dynamic>> _allTx = [
    {'title': '주차', 'type': 'payment',  'amount': -1500, 'createdAt': '2025-08-01'},
    {'title': '입금', 'type': 'deposit',  'amount': 30000, 'createdAt': '2025-08-01'},
    {'title': '출금', 'type': 'withdraw', 'amount': -5000, 'createdAt': '2025-07-31'},
  ];

  List<Map<String, dynamic>> get _filteredTx =>
      _allTx.where((e) => _filter == 'all' ? true : e['type'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 프로필
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: const [
                    Icon(Icons.person_outline, size: 72, color: Colors.black87),
                    SizedBox(height: 4),
                    Text('이바보', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              // 친구 찾기
              TextField(
                controller: _friendSearch,
                onSubmitted: (q) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FriendSearchPage(initialQuery: q)),
                  );
                },
                decoration: InputDecoration(
                  hintText: '친구 찾기',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFDED9F6),
                      child: Text(
                        (_friendSearch.text.trim().isEmpty
                            ? 'A'
                            : _friendSearch.text.trim()[0])
                            .toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: const Color(0xFFF2EFFA),
                ),
              ),
              const SizedBox(height: 12),

              // 잔액 카드
              CardContainer(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('내 지갑', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(_address, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    Text(
                      '${_won.format(_balance)}원',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 액션 버튼
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final res = await Navigator.of(context).push<Map<String, dynamic>>(
                          MaterialPageRoute(builder: (_) => const TransferPage()),
                        );
                        if (res != null && res['event'] == 'transfer_completed') {
                          final amount = res['amount'] as int;
                          final toName = res['toName'] as String;
                          final date   = res['date'] as String;
                          setState(() {
                            _balance -= amount;
                            _allTx.insert(0, {
                              'title': toName,
                              'type': 'payment',
                              'amount': -amount,
                              'createdAt': date,
                            });
                          });
                        }
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('송금'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RequestPage()),
                        );
                      },
                      icon: const Icon(Icons.request_page_outlined),
                      label: const Text('요청'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 필터 칩
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('전체', 'all'),
                    _chip('결제', 'payment'),
                    _chip('입금', 'deposit'),
                    _chip('출금', 'withdraw'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 요약 리스트 + + 버튼
              Expanded(
                child: CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text('전체 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          IconButton(
                            tooltip: '전체 화면으로 보기',
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionListPage(
                                    allTx: _allTx,
                                    initialFilter: _filter,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _filteredTx.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final it = _filteredTx[i];
                            final amt = it['amount'] as int;
                            return ListTile(
                              dense: true,
                              title: Text(it['title'] as String),
                              subtitle: Text(it['createdAt'] as String),
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
              ),
            ],
          ),
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
