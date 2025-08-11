import 'package:flutter/material.dart';
import '../wallet/wallet_page.dart';
import '../budget/budget_main_page.dart';
import 'home_page.dart';
import '../mobility/mobility_main_page.dart';
import '../settings/settings_main_page.dart';

class _Stub extends StatelessWidget {
  final String title;
  const _Stub(this.title, {super.key});
  @override
  Widget build(BuildContext context) =>
      SafeArea(child: Center(child: Text(title, style: const TextStyle(fontSize: 22))));
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.displayName});
  final String? displayName; // ← 추가

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _unread = 3;

  // ← const 리스트 대신 게터로 변경 (displayName 전달)
  List<Widget> get _pages => [
    HomePage(displayName: widget.displayName),
    WalletPage(displayName: widget.displayName),
    const BudgetPage(),
    const SettingsMainPage(),
    const MobilityMainPage(),
  ];

  bool get _useShellAppBar => _index != 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _useShellAppBar
          ? AppBar(
        title: Text(_titleForIndex(_index)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _NotificationPage()),
                );
                setState(() => _unread = 0);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.notifications_none),
                  ),
                  if (_unread > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _unread > 99 ? '99+' : '$_unread',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      )
          : null,
      body: IndexedStack(index: _index, children: _pages),
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

  String _titleForIndex(int i) {
    switch (i) {
      case 0: return 'HOME';
      case 1: return 'Wallet';
      case 2: return 'Budget';
      case 3: return 'Settings';
      case 4: return 'Mobility';
      default: return 'Molet';
    }
  }
}

class _NotificationPage extends StatelessWidget {
  const _NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.notifications),
          title: Text('알림 ${i + 1}'),
          subtitle: const Text('여기에 알림 내용을 표시합니다.'),
          onTap: () {},
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 10,
      ),
    );
  }
}
