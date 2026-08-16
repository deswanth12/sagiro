import 'models/subscription_plan.dart';
import 'models/premium_entitlement.dart';

enum PremiumFeature {
  privateSync,
  moneyReplay,
  advancedMoneyBrain,
  financialDna,
  unlimitedExports,
  premiumThemes,
  futureAiFeatures,
  earlyAccess,
}

class FeatureAccess {
  static PremiumEntitlement _currentEntitlement = PremiumEntitlement.free;

  static void updateEntitlement(PremiumEntitlement entitlement) {
    _currentEntitlement = entitlement;
  }

  static bool hasPremium() {
    return _currentEntitlement.isActive;
  }

  static bool canAccess(PremiumFeature feature) {
    if (hasPremium()) return true;

    // Feature gating rules for Free vs Pro
    switch (feature) {
      case PremiumFeature.privateSync:
      case PremiumFeature.moneyReplay:
      case PremiumFeature.advancedMoneyBrain:
      case PremiumFeature.financialDna:
      case PremiumFeature.unlimitedExports:
      case PremiumFeature.premiumThemes:
      case PremiumFeature.futureAiFeatures:
      case PremiumFeature.earlyAccess:
        return false; // Pro Tier features
    }
  }

  static SubscriptionPlanType get currentPlanType =>
      _currentEntitlement.planType;
}
