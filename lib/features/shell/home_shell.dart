import 'package:flutter/material.dart';
import '../wallet/wallet_page.dart';
import '../budget/budget_main_page.dart';

// 각 탭의 더미 화면
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
  int _unread = 3; // 임시: 안 읽은 알림 수(뱃지)

  final _pages = const [
    _Stub('home페이지'),
    WalletPage(),
    BudgetMainPage(),
    _Stub('설정 페이지'),
    _Stub('모빌리티 페이지'),
  ];

  bool get _useShellAppBar => _index != 1; // 지갑 탭(1)일 땐 Shell AppBar 숨김

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _useShellAppBar
          ? AppBar(
        title: Text(_titleForIndex(_index)),
        actions: [
          // 간단 뱃지(패키지 없이 Stack)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _NotificationPage()),
                );
                // 돌아오면 읽음 처리했다고 가정
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

//알림페이지
class _NotificationPage extends StatelessWidget {
  const _NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: /api/notifications 목록 불러와서 리스트로 렌더링
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.notifications),
          title: Text('알림 ${i + 1}'),
          subtitle: const Text('여기에 알림 내용을 표시합니다.'),
          onTap: () {}, // 상세로 이동 등
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 10,
      ),
    );
  }
}
