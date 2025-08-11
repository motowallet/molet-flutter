import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  static const _kBalance = 'wallet_balance';
  static const _kTx = 'wallet_tx';

  // === 이번 달 키 ===
  static String _ym([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}';
  }
  static String get _usedKey => 'budget_used_${_ym()}';

  // 앱 전체 공유 상태
  static final ValueNotifier<int> balanceVN = ValueNotifier<int>(100000);
  static final ValueNotifier<List<Map<String, dynamic>>> txVN =
  ValueNotifier<List<Map<String, dynamic>>>(const []);

  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;
    final sp = await SharedPreferences.getInstance();

    balanceVN.value = sp.getInt(_kBalance) ?? 100000;

    final raw = sp.getString(_kTx);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        txVN.value = list;
      } catch (_) {}
    }
    _loaded = true;
  }

  static Future<int> balance() async {
    await init();
    return balanceVN.value;
  }

  static Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kBalance, balanceVN.value);
    await sp.setString(_kTx, jsonEncode(txVN.value));
  }

  static void _addTx(Map<String, dynamic> tx) {
    txVN.value = [tx, ...txVN.value];
  }

  // === 이번 달 예산 사용액 증가 ===
  static Future<void> _bumpBudgetUsed(int amount) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_usedKey) ?? 0;
    await sp.setInt(_usedKey, cur + amount); // amount는 양수(절대값)
  }

  /// 결제(차감) + 거래내역 기록 + 예산사용액 증가
  /// [type]: 'withdraw' | 'payment' | 'deposit'
  static Future<bool> pay(
      int amount, {
        String title = '모빌리티 결제',
        String type = 'withdraw',
        String category = 'MOBILITY',
      }) async {
    await init();
    if (balanceVN.value < amount) return false;

    balanceVN.value -= amount;
    _addTx({
      'title': title,
      'type': type,
      'category': category,
      'amount': -amount,
      'createdAt': DateTime.now().toIso8601String().substring(0, 10),
    });
    await _bumpBudgetUsed(amount);
    await _persist();
    return true;
  }

  /// 입금(증가) + 거래내역 기록
  static Future<void> deposit(
      int amount, {
        String title = '입금',
        String category = 'DEPOSIT', // ← 추가
      }) async {
    await init();
    balanceVN.value += amount;
    _addTx({
      'title': title,
      'type': 'deposit',
      'category': category, // ← 이제 정상
      'amount': amount,
      'createdAt': DateTime.now().toIso8601String().substring(0, 10),
    });
    await _persist();
  }

  /// 송금(차감) + 거래내역 기록 + 예산사용액 증가
  static Future<bool> transfer(
      int amount, {
        required String toName,
        String category = 'TRANSFER', // ← 추가
      }) async {
    await init();
    if (balanceVN.value < amount) return false;

    balanceVN.value -= amount;
    _addTx({
      'title': toName,
      'type': 'payment',
      'category': category, // ← 카테고리 기록
      'amount': -amount,
      'createdAt': DateTime.now().toIso8601String().substring(0, 10),
    });
    await _bumpBudgetUsed(amount);
    await _persist();
    return true;
  }
}
