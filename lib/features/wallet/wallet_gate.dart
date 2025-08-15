import 'package:flutter/material.dart';
import '../home/home_shell.dart';
import '../wallet/wallet_service.dart';
import '../wallet/create_wallet_page.dart';

class WalletGate extends StatelessWidget {
  final String displayName;
  const WalletGate({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: WalletService.exists(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final exists = snap.data!;
        if (exists) {
          // 이미 지갑 있음 → 홈으로 교체 네비게이션
          Future.microtask(() {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => HomeShell(displayName: displayName)),
            );
          });
          return const SizedBox.shrink();
        } else {
          // 지갑 없음 → 한번만 보이는 생성 버튼 페이지
          return CreateWalletPage(displayName: displayName);
        }
      },
    );
  }
}
