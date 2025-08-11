import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'friend_search_page.dart';
import 'request_page.dart';
import 'transfer_page.dart';
import 'transaction_list_page.dart';
import 'card_container.dart';
import 'wallet_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, this.displayName});
  final String? displayName;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String _filter = 'all'; // all | payment | deposit | withdraw
  final _won = NumberFormat('#,###');
  final _friendSearch = TextEditingController();

  // TODO: 서버 연동(지갑 주소)
  final _address = '0xA1b2...9F';

  @override
  void dispose() {
    _friendSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileName =
    (widget.displayName?.trim().isEmpty ?? true) ? '사용자' : widget.displayName!.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 프로필
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    const Icon(Icons.person_outline, size: 72, color: Colors.black87),
                    const SizedBox(height: 4),
                    Text(
                      profileName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
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
                    ValueListenableBuilder<int>(
                      valueListenable: WalletService.balanceVN,
                      builder: (_, bal, __) => Text(
                        '${_won.format(bal)}원',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
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
                          await WalletService.transfer(amount, toName: toName);
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
                    _chip('송금', 'payment'),
                    _chip('입금', 'deposit'),
                    _chip('출금', 'withdraw'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 요약 리스트
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('전체 내역',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        IconButton(
                          tooltip: '전체 화면으로 보기',
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TransactionListPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 1),

                    ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: WalletService.txVN,
                      builder: (_, txs, __) {
                        final items = txs.where((e) {
                          final t = (e['type'] ?? '').toString();
                          return _filter == 'all' ? true : t == _filter;
                        }).toList()
                          ..sort((a, b) {
                            final da = (a['createdAt'] ?? '').toString();
                            final db = (b['createdAt'] ?? '').toString();
                            return db.compareTo(da);
                          });
                        final summary = items.take(5).toList();

                        if (summary.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('내역이 없습니다', style: TextStyle(color: Colors.black54)),
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: summary.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final it = summary[i];
                            final title = (it['title'] ?? '').toString();
                            final date = (it['createdAt'] ?? '').toString();
                            final type = (it['type'] ?? '').toString();
                            final num rawAmt = (it['amount'] is num) ? it['amount'] as num : 0;
                            final amt = rawAmt.toInt();
                            final isIncome = type == 'deposit';
                            final color = isIncome ? Colors.green : Colors.redAccent;

                            return ListTile(
                              dense: true,
                              title: Text(title.isEmpty ? '(제목 없음)' : title),
                              subtitle: Text(date),
                              trailing: Text(
                                '${amt < 0 ? '-' : '+'}${_won.format(amt.abs())}원',
                                style:
                                TextStyle(fontWeight: FontWeight.w700, color: color),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
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
