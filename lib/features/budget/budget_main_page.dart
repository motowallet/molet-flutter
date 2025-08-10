import 'package:flutter/material.dart';
import 'budget_limit_page.dart';
import 'budget_usage_page.dart';
import 'budget_report_page.dart';

class BudgetMainPage extends StatelessWidget {
  const BudgetMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 세로 가운데 정렬
          children: [
            _menuButton(context, "월별 예산 설정", const BudgetLimitPage()),
            _menuButton(context, "예산 사용률 확인", const BudgetUsagePage()),
            _menuButton(context, "소비 리포트 분석", const BudgetReportPage()),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String text, Widget page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 45), // 버튼 세로 크기 키움
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontSize: 20), // 글자 크기 키움
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 버튼 모서리 둥글게
            side: const BorderSide(color: Colors.black12), // 테두리
          ),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text,
          style: const TextStyle(color: Colors.black54),
        ),

            const SizedBox(width: 20),

            const Icon(Icons.chevron_right, size: 28), // 아이콘 크기 키움
          ],
        ),
      ),
    );
  }
}
