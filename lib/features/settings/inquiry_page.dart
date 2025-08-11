import 'package:flutter/material.dart';

class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});
  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  bool _sending = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    try {
      // 확실하지 않음: 실제 서버 연동 엔드포인트
      // TODO: await http.post('/support/inquiry', body: {...});
      await Future.delayed(const Duration(milliseconds: 600)); // mock
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의가 접수되었습니다.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전송 실패. 잠시 후 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('1:1 문의하기')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: '이메일(답변 수신)', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // 선택 입력
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
                  return ok ? null : '이메일 형식을 확인하세요';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(labelText: '문의 내용', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? '내용을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                label: const Text('보내기'),
                onPressed: _sending ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 8),
              Text('평일 09:00~18:00 순차적으로 답변드립니다.', style: t.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
