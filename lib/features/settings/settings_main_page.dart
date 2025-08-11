import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../wallet/wallet_page.dart';
import '../../main.dart'; // LoginPage
import 'dev_team_page.dart';
import 'terms_page.dart';
import 'language_page.dart';
import 'notice_list_page.dart';
import 'inquiry_page.dart';

class SettingsMainPage extends StatefulWidget {
  const SettingsMainPage({super.key});
  @override
  State<SettingsMainPage> createState() => _SettingsMainPageState();
}

class _SettingsMainPageState extends State<SettingsMainPage> {
  bool _pushEnabled = false;
  bool _busy = false;
  String _langCaption = '한국어';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _pushEnabled = await Prefs.getPushEnabled();
    _langCaption = await Prefs.getLangCaption();
    if (mounted) setState(() {});
  }

  Future<void> _setPush(bool v) async {
    setState(() => _pushEnabled = v);
    try {
      await Prefs.setPushEnabled(v); // ← 나중에 FCM 구독/해제를 여기서만 추가
    } catch (_) {
      if (!mounted) return;
      setState(() => _pushEnabled = !v);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('푸시 설정 변경에 실패했습니다.')),
      );
    }
  }

  Future<void> _logout() async {
    final ok = await _confirm('로그아웃 하시겠어요?');
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await AuthApi.logout(); // ← 서버/카카오 처리 한 곳
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
      _goLogin();
    }
  }

  Future<void> _withdraw() async {
    final ok = await _confirm('정말 탈퇴하시겠어요?\n모든 데이터가 삭제됩니다.');
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await AuthApi.withdraw(); // ← 서버/카카오 처리 한 곳
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  Future<bool> _confirm(String msg) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('확인'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _busy,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile(Icons.person, '사용자 정보', '월렛/프로필 보기', () async {
              String? nick;
              try {
                final me = await UserApi.instance.me();
                nick = me.kakaoAccount?.profile?.nickname;
              } catch (_) {}
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WalletPage(displayName: nick)),
              );
            }),
            _switchTile(Icons.notifications_active, '푸시 알림 설정', _pushEnabled, _setPush),

            // 앱 설정/지원
            _tile(Icons.language, '언어 설정', _langCaption, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguagePage()));
              if (mounted) {
                _langCaption = await Prefs.getLangCaption(); // 복귀 후 캡션 갱신
                setState(() {});
              }
            }),
            _tile(Icons.campaign_outlined, '공지사항', null, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeListPage()));
            }),
            _tile(Icons.chat_bubble_outline, '1:1 문의하기', null, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InquiryPage()));
            }),
            _tile(Icons.description_outlined, '이용 약관', null, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage()));
            }),
            _tile(Icons.groups_outlined, '개발진', 'Team & Advisor', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DevTeamPage()));
            }),

            const SizedBox(height: 8),
            // 위험 액션
            _danger(Icons.logout, '로그아웃', _logout),
            _danger(Icons.person_off, '회원탈퇴', _withdraw),

            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  // --- UI 헬퍼 ---
  Widget _tile(IconData i, String t, String? sub, VoidCallback onTap) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(i),
      title: Text(t),
      subtitle: sub == null ? null : Text(sub),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );

  Widget _switchTile(IconData i, String t, bool v, ValueChanged<bool> onChanged) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(i),
      title: Text(t),
      trailing: Switch(value: v, onChanged: onChanged),
    ),
  );

  Widget _danger(IconData i, String t, VoidCallback onTap) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(i, color: Colors.red),
      title: Text(t, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
      onTap: onTap,
    ),
  );
}

/* ===================== 여기만 바꾸면 백엔드 연동 끝 ===================== */

/// 인증 관련: 서버/카카오 호출을 한 곳에서 처리
class AuthApi {
  /// 로그아웃
  static Future<void> logout() async {
    // 1) (선택) 서버 로그아웃 API
    // TODO: await Http.post('/api/auth/logout');

    // 2) 소셜 세션 정리(카카오)
    try {
      await UserApi.instance.logout();
    } catch (_) {/* 서버만 쓰면 이 부분 삭제 */}
  }

  /// 회원탈퇴
  static Future<void> withdraw() async {
    // 1) (선택) 서버 회원탈퇴 API
    // TODO: await Http.delete('/api/users/me');

    // 2) 소셜 연결 해제(카카오)
    try {
      await UserApi.instance.unlink();
    } catch (_) {/* 서버만 쓰면 이 부분 삭제 */}
  }
}

/// 로컬 설정값(푸시/언어) 관리
class Prefs {
  static const _kPush = 'push_enabled';
  static const _kLang = 'app_lang';

  static Future<bool> getPushEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kPush) ?? false;
    // FCM 붙일 땐 여기선 읽기만 유지, 구독/해제는 set에서 처리
  }

  static Future<void> setPushEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPush, v);

    // TODO: FCM 구독/해제 3줄만 추가하면 완성
    // final fcm = FirebaseMessaging.instance;
    // if (v) {
    //   final perm = await fcm.requestPermission(alert: true, badge: true, sound: true);
    //   if (perm.authorizationStatus.index < 1) throw Exception('denied');
    //   await fcm.subscribeToTopic('all');
    // } else {
    //   await fcm.unsubscribeFromTopic('all');
    // }
  }

  static Future<String> getLangCaption() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_kLang) ?? 'ko';
    return code == 'en' ? 'English' : '한국어';
  }
}
