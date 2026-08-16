import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'billing_constants.dart';
import 'models/premium_entitlement.dart';
import 'models/subscription_plan.dart';

class BillingRepository {
  final FlutterSecureStorage _secureStorage;

  BillingRepository({FlutterSecureStorage? storage})
      : _secureStorage = storage ?? const FlutterSecureStorage();

  Future<void> saveEntitlement({
    required SubscriptionPlanType planType,
    required String purchaseToken,
    required DateTime purchaseDate,
    DateTime? expiryDate,
    String? firebaseUid,
  }) async {
    await _secureStorage.write(
        key: BillingConstants.keyPlanType, value: planType.index.toString());
    await _secureStorage.write(
        key: BillingConstants.keyPurchaseToken, value: purchaseToken);
    await _secureStorage.write(
        key: BillingConstants.keyPurchaseDate,
        value: purchaseDate.toIso8601String());
    if (expiryDate != null) {
      await _secureStorage.write(
          key: BillingConstants.keyExpiryDate,
          value: expiryDate.toIso8601String());
    } else {
      await _secureStorage.delete(key: BillingConstants.keyExpiryDate);
    }
    await _secureStorage.write(
        key: BillingConstants.keyPremiumStatus,
        value: planType.isPro ? 'true' : 'false');
    if (firebaseUid != null) {
      await _secureStorage.write(
          key: BillingConstants.keyFirebaseUid, value: firebaseUid);
    }
  }

  Future<PremiumEntitlement> loadEntitlement() async {
    try {
      final planIndexStr =
          await _secureStorage.read(key: BillingConstants.keyPlanType);
      final token =
          await _secureStorage.read(key: BillingConstants.keyPurchaseToken);
      final purchaseDateStr =
          await _secureStorage.read(key: BillingConstants.keyPurchaseDate);
      final expiryDateStr =
          await _secureStorage.read(key: BillingConstants.keyExpiryDate);
      final statusStr =
          await _secureStorage.read(key: BillingConstants.keyPremiumStatus);
      final uid =
          await _secureStorage.read(key: BillingConstants.keyFirebaseUid);

      if (planIndexStr == null || statusStr != 'true') {
        return PremiumEntitlement.free;
      }

      final planIndex = int.tryParse(planIndexStr) ?? 0;
      final planType =
          (planIndex >= 0 && planIndex < SubscriptionPlanType.values.length)
              ? SubscriptionPlanType.values[planIndex]
              : SubscriptionPlanType.free;
      final purchaseDate =
          purchaseDateStr != null ? DateTime.tryParse(purchaseDateStr) : null;
      final expiryDate =
          expiryDateStr != null ? DateTime.tryParse(expiryDateStr) : null;

      final entitlement = PremiumEntitlement(
        planType: planType,
        purchaseToken: token,
        firebaseUid: uid,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        isEntitled: true,
      );

      return entitlement.isActive ? entitlement : PremiumEntitlement.free;
    } catch (_) {
      return PremiumEntitlement.free;
    }
  }

  Future<void> clearEntitlement() async {
    await _secureStorage.delete(key: BillingConstants.keyPlanType);
    await _secureStorage.delete(key: BillingConstants.keyPurchaseToken);
    await _secureStorage.delete(key: BillingConstants.keyPurchaseDate);
    await _secureStorage.delete(key: BillingConstants.keyExpiryDate);
    await _secureStorage.delete(key: BillingConstants.keyPremiumStatus);
    await _secureStorage.delete(key: BillingConstants.keyFirebaseUid);
  }
}
