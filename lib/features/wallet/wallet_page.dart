import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String _filter = 'all'; // all|payment|deposit|withdraw
  final _won = NumberFormat('#,###');

  // TODO: 서버 데이터로 교체
  final _address = '0xA1b2...9F';
  final _balance = 9876543;

  List<Map<String, dynamic>> get _list => [
    {'title': '주차', 'type': 'payment', 'amount': -1500, 'createdAt': '2025-08-01'},
    {'title': '입금', 'type': 'deposit', 'amount': 30000, 'createdAt': '2025-08-01'},
    {'title': '출금', 'type': 'withdraw', 'amount': -5000, 'createdAt': '2025-07-31'},
  ].where((e) => _filter == 'all' ? true : e['type'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지갑')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 잔액 카드
              _Card(
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

              // 액션 버튼 (송금/요청)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TransferPage()),
                        );
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

              // 거래 리스트
              Expanded(
                child: _Card(
                  child: ListView.separated(
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = _list[i];
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// ====================
/// 송금 페이지 (친구 선택 → 금액 입력 → 확인 → 완료)
/// ====================
class TransferPage extends StatefulWidget {
  const TransferPage({super.key});
  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _search = TextEditingController();
  final _friends = List.generate(
    10,
        (i) => {'name': '이바보$i', 'address': '0xABCD...$i'},
  );
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _friends
        .where((f) => f['name']!.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('송금 - 친구 선택')),
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
                    final amount = await _showAmountSheet(context);
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

                    // TODO: 송금 API 호출
                    await Future.delayed(const Duration(milliseconds: 400));

                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const _SuccessPage(title: '송금이 완료되었습니다')),
                    );
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

/// ====================
/// 요청 페이지 (친구 선택 → 금액 입력 → 확인 → 완료)
/// ====================
class RequestPage extends StatefulWidget {
  const RequestPage({super.key});
  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _search = TextEditingController();
  final _friends = List.generate(
    10,
        (i) => {'name': '이가나$i', 'address': '0x1234...$i'},
  );
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _friends
        .where((f) => f['name']!.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('요청 - 친구 선택')),
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
                    final amount = await _showAmountSheet(context);
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

                    // TODO: 요청 API 호출
                    await Future.delayed(const Duration(milliseconds: 400));

                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const _SuccessPage(title: '요청이 완료되었습니다')),
                    );
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

/// ====================
/// 공용: 금액 입력 BottomSheet
/// ====================
Future<int?> _showAmountSheet(BuildContext context) async {
  final controller = TextEditingController(text: '10000');
  final formKey = GlobalKey<FormState>();
  final won = NumberFormat('#,###');

  final result = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('금액 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                validator: (v) {
                  final n = int.tryParse(v?.replaceAll(',', '') ?? '');
                  if (n == null || n <= 0) return '올바른 금액을 입력하세요';
                  return null;
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) {
                  final raw = v.replaceAll(',', '');
                  final n = int.tryParse(raw);
                  if (n == null) return;
                  final t = won.format(n);
                  controller.value = TextEditingValue(
                    text: t,
                    selection: TextSelection.collapsed(offset: t.length),
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final n = int.parse(controller.text.replaceAll(',', ''));
                  Navigator.pop(ctx, n);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result;
}

/// ====================
/// 공용: 완료 화면
/// ====================
class _SuccessPage extends StatelessWidget {
  final String title;
  const _SuccessPage({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('완료')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 96, color: Colors.blueGrey),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
