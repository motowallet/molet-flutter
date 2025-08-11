import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../wallet/wallet_service.dart';
import '../wallet/wallet_prefs.dart';
import 'plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.displayName});
  final String? displayName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _walletName = 'hiwallet';
  final _won = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    _walletName = await WalletPrefs.getName();
    if (mounted) setState(() {});
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: _walletName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('지갑 이름 변경'),
        content: TextField(
          controller: c,
          maxLength: 20,
          decoration: const InputDecoration(hintText: '지갑 이름 입력'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok == true) {
      final v = c.text.trim().isEmpty ? 'hiwallet' : c.text.trim();
      await WalletPrefs.setName(v);
      if (mounted) setState(() => _walletName = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (widget.displayName?.trim().isEmpty ?? true) ? '이바보' : widget.displayName!.trim();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Stack(
              children: [
                // 실제 내용
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Hello $name,',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),

                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFFE5E7EB),
                            child: Icon(Icons.person_outline, color: Colors.black87),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Bubble(
                              color: const Color(0xFFE6E7EA),
                              tailLeft: true,
                              child: ValueListenableBuilder<int>(
                                valueListenable: WalletService.balanceVN,
                                builder: (_, bal, __) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('잔액', style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 4),
                                    Text('${_won.format(bal)}원',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(children: [
                        const SizedBox(width: 56),
                        Expanded(
                          child: _Bubble(
                            color: const Color(0xFFD8D9FF),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('나의 지갑', style: theme.textTheme.bodySmall),
                                      const SizedBox(height: 6),
                                      Text(_walletName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: '지갑 이름 변경',
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: _editName,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 30),

                      const Center(child: PlusPet(size: 88, emoji: '🪙')),

                      const SizedBox(height: 20),

                      const Center(child: FortuneSticker()),

                      const SizedBox(height: 30),

                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.child, required this.color, this.tailLeft = false});
  final Widget child;
  final Color color;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: child,
      ),
      Positioned(
        left: tailLeft ? -4 : null, right: tailLeft ? null : -4, bottom: 8,
        child: Transform.rotate(
          angle: 0.8,
          child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
        ),
      ),
    ]);
  }
}
