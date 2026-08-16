enum SubscriptionTier {
  free,
  proMonthly,
  proYearly,
}

extension SubscriptionTierExtension on SubscriptionTier {
  bool get isPro => this != SubscriptionTier.free;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free Plan';
      case SubscriptionTier.proMonthly:
        return 'Pro Monthly (₹99/mo)';
      case SubscriptionTier.proYearly:
        return 'Pro Yearly (₹799/yr)';
    }
  }

  String get badgeText {
    switch (this) {
      case SubscriptionTier.free:
        return 'FREE';
      case SubscriptionTier.proMonthly:
        return 'PRO';
      case SubscriptionTier.proYearly:
        return 'PRO YEARLY';
    }
  }
}

/// Centralized FeatureAccess Service — Single Source of Truth for Freemium Gating.
/// Controls access to Sagiro features based on active user subscription tier.
class FeatureAccess {
  static const String skuProLifetime = 'com.sagiro.pro.lifetime';
  static const String skuProMonthly = 'com.sagiro.pro.monthly';
  static const String skuProYearly = 'com.sagiro.pro.yearly';

  // Feature Gating Checks

  /// AI Financial Coach (Free: 50 Tokens Quota, Pro: Unlimited)
  static bool canUseAI(SubscriptionTier tier) => tier.isPro;

  /// Monthly Money Story
  static bool canUseMoneyStory(SubscriptionTier tier) => tier.isPro;

  /// Financial Twin Simulator
  static bool canUseFinancialTwin(SubscriptionTier tier) => tier.isPro;

  /// Password Encrypted Backups (.ppbackup SHA-256 stream)
  static bool canUseEncryptedBackup(SubscriptionTier tier) => tier.isPro;

  /// Premium Obsidian Themes & Custom Icons
  static bool canUsePremiumThemes(SubscriptionTier tier) => tier.isPro;

  /// Priority 24/7 Support
  static bool canUsePrioritySupport(SubscriptionTier tier) => tier.isPro;

  /// Advanced Merchant Breakdown & High-Order Spend Analytics
  static bool canUseAdvancedAnalytics(SubscriptionTier tier) => tier.isPro;

  /// Advanced Velocity Pacing Forecast
  static bool canUseAdvancedForecast(SubscriptionTier tier) => tier.isPro;

  /// Standard Features Available to ALL Users (Never Crippled)
  static bool canUseSmsTracking() => true;
  static bool canUseManualTransactions() => true;
  static bool canUseCsvImport() => true;
  static bool canUseBudgetDashboard() => true;
  static bool canUseMerchantIntelligence() => true;
  static bool canUseSubscriptionDetector() => true;
  static bool canUseSmartCategories() => true;
  static bool canUseLocalSafBackup() => true;
}
