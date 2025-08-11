import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('이용 약관')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            // TODO: 실제 약관 텍스트/마크다운 자산으로 교체
            '''[샘플 약관]
1. 목적: 본 약관은 Molet 서비스 이용에 관한 조건·절차를 규정합니다.
2. 계정: 사용자는 정확한 정보를 제공해야 하며, 타인의 권리를 침해할 수 없습니다.
3. 결제/환불: 관련 법령 및 별도 정책에 따릅니다.
4. 개인정보: 개인정보 처리방침을 따릅니다.
5. 금지행위: 불법행위, 시스템 오남용, 타인 사칭 등.
6. 책임제한: 불가항력적 사유에 대해서는 책임을 지지 않습니다.
7. 약관변경: 사전 고지 후 변경될 수 있습니다.
(이하 생략)
''',
            style: t.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
