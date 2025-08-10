import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: const String.fromEnvironment('KAKAO_NATIVE_APP_KEY'));
  runApp(const MoletApp());
}

class MoletApp extends StatelessWidget {
  const MoletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Molet Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String _msg = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _msg = '';
    });
    try {
      final installed = await isKakaoTalkInstalled();
      final token = installed
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      // TODO: 여기서 백엔드로 카카오 토큰 전달 -> JWT 발급 (/api/auth/login)
      setState(() {
        _msg = '카카오 토큰 받음: ${token.accessToken.substring(0, 8)}...';
      });
    } catch (e) {
      setState(() {
        _msg = '로그인 실패: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 안전 영역 + 가운데 정렬 + 하단 버튼 고정
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  const Spacer(),
                  // 중앙 로고
                  Column(
                    children: [
                      Image.asset(
                        'assets/molet.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DRIVE, PAY, DONE',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 하단 카카오 로그인 버튼(이미지)
                  SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _loading ? null : _login,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 버튼 이미지
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/kakaologin.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          // 로딩 표시
                          if (_loading)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Colors.black26,
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _msg,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
