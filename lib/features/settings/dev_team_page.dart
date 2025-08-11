import 'package:flutter/material.dart';

class DevTeamPage extends StatelessWidget {
  const DevTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final team = [
      {'name': '김예진', 'role': 'Hardware R&D Engineer'},
      {'name': '박지수', 'role': 'Embedded Systems Engineer'},
      {'name': '이영흔', 'role': 'Mobile App Developer'},
      {'name': '이윤정', 'role': 'Blockchain & Backend Developer'},
      {'name': '채승민', 'role': 'Backend Developer'},
    ];
    final advisors = [
      {'name': '신승훈', 'role': 'Project Mentor'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('개발진'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Team'),
          const SizedBox(height: 8),
          ...team.map(_memberTile).expand((w) => [w, const Divider(height: 1)]).toList()
            ..removeLast(),
          const SizedBox(height: 24),
          _sectionHeader('Advisor'),
          const SizedBox(height: 8),
          ...advisors.map(_memberTile).expand((w) => [w, const Divider(height: 1)]).toList()
            ..removeLast(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _memberTile(Map<String, String> m) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          m['name']!.substring(0, 1),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      title: Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(m['role']!, style: TextStyle(color: Colors.grey.shade700)),
      dense: true,
    );
  }
}
