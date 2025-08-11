import 'package:shared_preferences/shared_preferences.dart';

class WalletPrefs {
  static const _kName = 'wallet_name';

  static Future<String> getName() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kName) ?? 'hiwallet';
  }

  static Future<void> setName(String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, value.trim());
  }
}
