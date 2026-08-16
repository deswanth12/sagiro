import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  static const String _prefReferralCodeKey = 'user_referral_code';
  static const String _prefRedeemedCodeKey = 'redeemed_referral_code';
  static const String _prefProDaysEarnedKey = 'pro_days_earned';

  // Generate or retrieve user's unique 6-character referral code
  static Future<String> getUserReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(_prefReferralCodeKey);
    if (code == null) {
      final random = Random();
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final randomStr =
          List.generate(6, (index) => chars[random.nextInt(chars.length)])
              .join();
      code = 'PAISA-$randomStr';
      await prefs.setString(_prefReferralCodeKey, code);
    }
    return code;
  }

  // Redeem a friend's referral code and grant 30 Days Pro
  static Future<bool> redeemReferralCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final userCode = await getUserReferralCode();

    // Cannot redeem own code
    if (cleanCode == userCode) return false;

    // Save redeemed code
    await prefs.setString(_prefRedeemedCodeKey, cleanCode);
    final currentEarned = prefs.getInt(_prefProDaysEarnedKey) ?? 0;
    await prefs.setInt(_prefProDaysEarnedKey, currentEarned + 30);
    return true;
  }

  // Get total Pro days earned via referrals
  static Future<int> getProDaysEarned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefProDaysEarnedKey) ?? 0;
  }
}
