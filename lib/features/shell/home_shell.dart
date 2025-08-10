import 'package:flutter/material.dart';
//import '../home/home_page.dart';
import '../wallet/wallet_page.dart';
// 각 탭의 더미 화면 (필요해지면 실제 화면으로 교체)
class _Stub extends StatelessWidget {
  final String title;
  const _Stub(this.title, {super.key});
  @override
  Widget build(BuildContext context) =>
      SafeArea(child: Center(child: Text(title, style: const TextStyle(fontSize: 22))));
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    _Stub('home페이지'),
    WalletPage(),
    _Stub('예산 페이지'),
    _Stub('설정 페이지'),
    _Stub('모빌리티 페이지'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages), // 탭 상태 유지
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: '지갑'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: '예산'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '설정'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), label: '모빌리티'),
        ],
      ),
    );
  }
}
