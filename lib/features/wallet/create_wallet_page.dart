import 'package:flutter/material.dart';
import '../home/home_shell.dart';
import 'wallet_service.dart';

class CreateWalletPage extends StatefulWidget {
  final String displayName;
  const CreateWalletPage({super.key, required this.displayName});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await WalletService.createWallet(initialBalance: 100000);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeShell(displayName: widget.displayName)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('첫 지갑을 만들어볼까요?', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('결제·송금·입금을 시작하려면 지갑이 필요해요.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _create,
                      child: _busy
                          ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('지갑 생성하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
