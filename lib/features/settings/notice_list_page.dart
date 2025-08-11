import 'package:flutter/material.dart';

class NoticeListPage extends StatelessWidget {
  const NoticeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = <_Notice>[
      _Notice(title: '정기 점검 안내', date: '2025-08-15', content: '08/15 02:00~03:00 서버 점검이 진행됩니다.'),
      _Notice(title: '버전 1.1 업데이트', date: '2025-08-05', content: '지갑 이체 속도 개선 및 버그 수정.'),
      _Notice(title: '개인정보 처리방침 개정', date: '2025-07-30', content: '수집 항목 및 보관 기간이 일부 변경됩니다.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: notices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final n = notices[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(n.date),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(alignment: Alignment.centerLeft, child: Text(n.content)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Notice {
  final String title, date, content;
  const _Notice({required this.title, required this.date, required this.content});
}
