import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'billing_constants.dart';
import 'billing_repository.dart';
import 'models/subscription_plan.dart';
import 'models/premium_entitlement.dart';

class RestorePurchaseService {
  final InAppPurchase? _iapInstance;
  InAppPurchase get _iap => _iapInstance ?? InAppPurchase.instance;
  final BillingRepository _repository;

  RestorePurchaseService({InAppPurchase? iap, BillingRepository? repository})
      : _iapInstance = iap,
        _repository = repository ?? BillingRepository();

  Future<PremiumEntitlement> restorePurchases() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      throw Exception('Google Play Store is unavailable.');
    }

    Completer<PremiumEntitlement> completer = Completer();
    StreamSubscription<List<PurchaseDetails>>? subscription;

    subscription = _iap.purchaseStream.listen((purchaseList) async {
      for (var purchase in purchaseList) {
        if (purchase.status == PurchaseStatus.restored ||
            purchase.status == PurchaseStatus.purchased) {
          final planType = _resolvePlanType(purchase.productID);
          final entitlement = PremiumEntitlement(
            planType: planType,
            purchaseToken: purchase.verificationData.serverVerificationData,
            purchaseDate: DateTime.now(),
            expiryDate: planType == SubscriptionPlanType.proYearly
                ? DateTime.now().add(const Duration(days: 365))
                : (planType == SubscriptionPlanType.proMonthly
                    ? DateTime.now().add(const Duration(days: 30))
                    : null),
            isEntitled: true,
          );

          await _repository.saveEntitlement(
            planType: planType,
            purchaseToken: purchase.verificationData.serverVerificationData,
            purchaseDate: DateTime.now(),
            expiryDate: entitlement.expiryDate,
          );

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

          if (!completer.isCompleted) {
            completer.complete(entitlement);
            await subscription?.cancel();
            subscription = null;
          }
        }
      }
    });

    await _iap.restorePurchases();

    // Timeout fallback if no active restored purchases exist on the Google Play account
    Future.delayed(const Duration(seconds: 4), () {
      if (!completer.isCompleted) {
        completer.complete(PremiumEntitlement.free);
      }
      subscription?.cancel();
      subscription = null;
    });

    return completer.future;
  }

  SubscriptionPlanType _resolvePlanType(String sku) {
    if (sku == BillingConstants.skuProMonthly) {
      return SubscriptionPlanType.proMonthly;
    }
    if (sku == BillingConstants.skuProYearly) {
      return SubscriptionPlanType.proYearly;
    }
    if (sku == BillingConstants.skuProLifetime) {
      return SubscriptionPlanType.proLifetime;
    }
    return SubscriptionPlanType.free;
  }
}
