import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'features/home/home_shell.dart';
import 'features/wallet/wallet_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 지갑/거래내역 초기화 (앱 첫 화면 뜨기 전)
  await WalletService.init();

  // 하나의 환경변수로 통일해서 JS키 주입
  const jsKey = String.fromEnvironment('KAKAO_JAVASCRIPT_APP_KEY');

  KakaoSdk.init(
    nativeAppKey: const String.fromEnvironment('KAKAO_NATIVE_APP_KEY'),
    javaScriptAppKey: jsKey,
  );

  // kakao_map_plugin용 초기화 (JS 키 동일 사용)
  AuthRepository.initialize(appKey: jsKey);

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
      OAuthToken token;
      final installed = await isKakaoTalkInstalled();

      if (installed) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (_) {
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      final me = await UserApi.instance.me();
      final nick = me.kakaoAccount?.profile?.nickname ?? '사용자';

      if (!mounted) return;
      setState(() {
        _msg = '로그인 성공: $nick (${token.accessToken.substring(0, 8)}...)';
      });

      // TODO: 백엔드에 token.accessToken 전달해 JWT 발급/저장

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeShell(displayName: nick)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msg = '로그인 실패: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Column(
                    children: [
                      Image.asset('assets/molet.png', height: 250, fit: BoxFit.contain),
                      const SizedBox(height: 11),
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
                  SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _loading ? null : _login,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/kakaologin.png', fit: BoxFit.contain),
                          ),
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
                  Text(_msg, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
