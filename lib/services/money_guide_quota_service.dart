import 'package:shared_preferences/shared_preferences.dart';

/// MoneyGuideQuotaService — Manages token quota for the Money Guide AI Assistant.
/// Free users get a total quota of 50 tokens (1 token per prompt).
/// Pro users get unlimited tokens.
class MoneyGuideQuotaService {
  static const int maxFreeTokens = 50;
  static const String _kUsedTokensKey = 'money_guide_used_tokens_v1';

  /// Get total number of tokens consumed by the free user.
  static Future<int> getUsedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kUsedTokensKey) ?? 0;
  }

  /// Get remaining tokens.
  /// Returns -1 for Pro users (representing Unlimited).
  /// For Free users, returns [maxFreeTokens] - usedTokens (clamped to 0).
  static Future<int> getRemainingTokens(bool isPro) async {
    if (isPro) return -1; // -1 represents Unlimited
    final used = await getUsedTokens();
    final remaining = maxFreeTokens - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Check if the user has tokens available to send a query.
  static Future<bool> canConsumeToken(bool isPro) async {
    if (isPro) return true;
    final remaining = await getRemainingTokens(false);
    return remaining > 0;
  }

  /// Consumes 1 token for Free users.
  /// Does nothing for Pro users.
  /// Returns the updated remaining token count (-1 for Pro).
  static Future<int> consumeToken(bool isPro) async {
    if (isPro) return -1;
    final prefs = await SharedPreferences.getInstance();
    final currentUsed = prefs.getInt(_kUsedTokensKey) ?? 0;
    final newUsed = currentUsed + 1;
    await prefs.setInt(_kUsedTokensKey, newUsed);
    final remaining = maxFreeTokens - newUsed;
    return remaining < 0 ? 0 : remaining;
  }

  /// Reset quota (useful for testing or administrative resets).
  static Future<void> resetQuota() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsedTokensKey);
  }
}
