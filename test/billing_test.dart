import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/billing/billing_provider.dart';
import 'package:sagiro/billing/billing_service.dart';
import 'package:sagiro/billing/subscription_manager.dart';
import 'package:sagiro/billing/restore_purchase_service.dart';
import 'package:sagiro/billing/models/premium_entitlement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Billing System Unit Tests', () {
    test('BillingProvider initializes with free entitlement', () {
      final provider = BillingProvider(
        billingService: BillingService(),
        subscriptionManager: SubscriptionManager(),
        restoreService: RestorePurchaseService(),
      );

      expect(provider.isPro, isFalse);
      expect(provider.entitlement, equals(PremiumEntitlement.free));
    });
  });
}
