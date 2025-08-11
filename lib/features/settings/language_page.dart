import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});
  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _lang = 'ko';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() => _lang = sp.getString('app_lang') ?? 'ko');
  }

  Future<void> _set(String code) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('app_lang', code);
    setState(() => _lang = code);
    // 확실하지 않음: 실시간 Locale 반영은 앱 루트에서 처리 필요(예: Provider/Bloc)
    // TODO: MaterialApp locale을 변경하도록 notify
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('언어가 저장되었습니다: $code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('언어 설정')),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: const Text('한국어'),
            value: 'ko',
            groupValue: _lang,
            onChanged: (v) => _set(v!),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: _lang,
            onChanged: (v) => _set(v!),
          ),
        ],
      ),
    );
  }
}
