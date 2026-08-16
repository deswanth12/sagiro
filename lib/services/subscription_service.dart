import 'package:shared_preferences/shared_preferences.dart';
import 'feature_access.dart';
import 'billing_service.dart';

/// SubscriptionService — Local Subscription Manager & Offline Privacy Analytics.
class SubscriptionService {
  static const String _kPremiumClicksKey = 'analytics_premium_clicks';
  static const String _kUpgradeAttemptsKey = 'analytics_upgrade_attempts';
  static const String _kPurchaseSuccessKey = 'analytics_purchase_success';

  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  Future<void> initialize() async {
    _currentTier = await BillingService.getCachedSubscriptionTier();
  }

  void setTier(SubscriptionTier tier) {
    _currentTier = tier;
  }

  // ── LOCAL PRIVACY ANALYTICS (100% On-Device Local Storage) ──────

  Future<void> trackPremiumClick() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kPremiumClicksKey) ?? 0;
    await prefs.setInt(_kPremiumClicksKey, count + 1);
  }

  Future<void> trackUpgradeAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kUpgradeAttemptsKey) ?? 0;
    await prefs.setInt(_kUpgradeAttemptsKey, count + 1);
  }

  Future<void> trackPurchaseSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kPurchaseSuccessKey) ?? 0;
    await prefs.setInt(_kPurchaseSuccessKey, count + 1);
  }
}
