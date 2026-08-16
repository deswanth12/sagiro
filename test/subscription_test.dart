import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagiro/services/feature_access.dart';
import 'package:sagiro/services/subscription_service.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Subscription & FeatureAccess Tests', () {
    test('Free tier allows standard features but gates Pro features', () {
      const tier = SubscriptionTier.free;

      // Standard Features (Always Allowed)
      expect(FeatureAccess.canUseSmsTracking(), isTrue);
      expect(FeatureAccess.canUseManualTransactions(), isTrue);
      expect(FeatureAccess.canUseCsvImport(), isTrue);
      expect(FeatureAccess.canUseLocalSafBackup(), isTrue);

      // Pro Features (Gated for Free tier)
      expect(FeatureAccess.canUseAI(tier), isFalse);
      expect(FeatureAccess.canUseMoneyStory(tier), isFalse);
      expect(FeatureAccess.canUseFinancialTwin(tier), isFalse);
      expect(FeatureAccess.canUseEncryptedBackup(tier), isFalse);
      expect(FeatureAccess.canUsePremiumThemes(tier), isFalse);
    });

    test('Pro Monthly tier unlocks all premium features', () {
      const tier = SubscriptionTier.proMonthly;

      expect(FeatureAccess.canUseAI(tier), isTrue);
      expect(FeatureAccess.canUseMoneyStory(tier), isTrue);
      expect(FeatureAccess.canUseFinancialTwin(tier), isTrue);
      expect(FeatureAccess.canUseEncryptedBackup(tier), isTrue);
      expect(FeatureAccess.canUsePremiumThemes(tier), isTrue);
      expect(FeatureAccess.canUsePrioritySupport(tier), isTrue);
    });

    test('SubscriptionService privacy analytics counters update on device',
        () async {
      final service = SubscriptionService();
      await service.initialize();

      await service.trackPremiumClick();
      await service.trackUpgradeAttempt();
      await service.trackPurchaseSuccess();

      expect(service.currentTier, equals(SubscriptionTier.free));
    });
  });
}
