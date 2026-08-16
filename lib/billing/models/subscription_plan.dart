enum SubscriptionPlanType {
  free,
  proMonthly,
  proYearly,
  proLifetime,
}

extension SubscriptionPlanTypeX on SubscriptionPlanType {
  bool get isPro => this != SubscriptionPlanType.free;
  bool get isLifetime => this == SubscriptionPlanType.proLifetime;

  String get displayName {
    switch (this) {
      case SubscriptionPlanType.free:
        return 'Free Tier';
      case SubscriptionPlanType.proMonthly:
        return 'Pro Monthly';
      case SubscriptionPlanType.proYearly:
        return 'Pro Yearly';
      case SubscriptionPlanType.proLifetime:
        return 'Lifetime Pro (₹699)';
    }
  }

  String get skuId {
    switch (this) {
      case SubscriptionPlanType.free:
        return '';
      case SubscriptionPlanType.proMonthly:
        return 'com.sagiro.pro.monthly';
      case SubscriptionPlanType.proYearly:
        return 'com.sagiro.pro.yearly';
      case SubscriptionPlanType.proLifetime:
        return 'com.sagiro.pro.lifetime';
    }
  }
}

class SubscriptionPlan {
  final SubscriptionPlanType type;
  final String skuId;
  final String title;
  final String priceFormatted;
  final String periodFormatted;
  final String? badgeText;
  final List<String> features;

  const SubscriptionPlan({
    required this.type,
    required this.skuId,
    required this.title,
    required this.priceFormatted,
    required this.periodFormatted,
    this.badgeText,
    required this.features,
  });

  static const SubscriptionPlan free = SubscriptionPlan(
    type: SubscriptionPlanType.free,
    skuId: '',
    title: 'Sagiro Free',
    priceFormatted: '₹0',
    periodFormatted: 'forever free',
    features: [
      'Safe Today™ daily budget pacing',
      'Timeline Feed with search',
      'Financial Calendar bill view',
      'SMS Auto Tracking offline',
      'Unlimited manual transactions',
      'Manual accounts & categories',
      'Money Brain™ basic guidance',
      'Local backup & restore',
      '100% On-Device Privacy',
    ],
  );

  static const SubscriptionPlan proMonthly = SubscriptionPlan(
    type: SubscriptionPlanType.proMonthly,
    skuId: 'com.sagiro.pro.monthly',
    title: 'Pro Monthly',
    priceFormatted: '₹67',
    periodFormatted: '/ month',
    features: [
      'Biometric Fingerprint & Screen App Lock',
      'Mask & Unmask Balance Privacy Mode',
      'Private Sync™ Google Drive E2EE',
      'Money Replay™ yearly stories',
      'Advanced Money Brain™ Q&A',
      'Financial DNA™ insights',
      'Unlimited exports & themes',
    ],
  );

  static const SubscriptionPlan proYearly = SubscriptionPlan(
    type: SubscriptionPlanType.proYearly,
    skuId: 'com.sagiro.pro.yearly',
    title: 'Pro Yearly',
    priceFormatted: '₹499',
    periodFormatted: '/ year',
    badgeText: 'ANNUAL SAVER',
    features: [
      'Everything in Pro Monthly',
      'Biometric Fingerprint & Screen App Lock',
      'Mask & Unmask Balance Privacy Mode',
      'Save 40% vs Monthly',
      'Early Access Features',
      'Insider Preview Program',
    ],
  );

  static const SubscriptionPlan proLifetime = SubscriptionPlan(
    type: SubscriptionPlanType.proLifetime,
    skuId: 'com.sagiro.pro.lifetime',
    title: 'Lifetime Pro',
    priceFormatted: '₹699',
    periodFormatted: 'Pay Once. Own Forever.',
    badgeText: '⭐ MOST POPULAR • PAY ONCE, OWN FOREVER',
    features: [
      'Biometric Fingerprint & Screen App Lock',
      'Mask & Unmask Balance Privacy Mode',
      'Private Sync™ — Your Cloud, Key, Data',
      'Money Replay™ — Save Replays Forever',
      'Advanced Money Brain™ — Ask Questions & Guidance',
      'Financial DNA™ — Behavioral Insights',
      'Founder Supporter Badge',
      'Early Access Features',
      'Insider Preview Program',
      'Premium Themes & Unlimited Exports',
    ],
  );
}
