import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'billing_constants.dart';
import 'billing_repository.dart';
import 'models/premium_entitlement.dart';
import 'models/subscription_plan.dart';
import 'purchase_manager.dart';

class BillingService {
  final PurchaseManager _purchaseManager;
  final BillingRepository _repository;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Function(PremiumEntitlement)? _onEntitlementUpdated;
  Function(String)? _onErrorOccurred;

  BillingService(
      {PurchaseManager? purchaseManager, BillingRepository? repository})
      : _purchaseManager = purchaseManager ?? PurchaseManager(),
        _repository = repository ?? BillingRepository();

  Future<void> initialize({
    Function(PremiumEntitlement)? onEntitlementUpdated,
    Function(String)? onErrorOccurred,
  }) async {
    _onEntitlementUpdated = onEntitlementUpdated;
    _onErrorOccurred = onErrorOccurred;

    final isAvailable = await _purchaseManager.isStoreAvailable();
    if (!isAvailable) {
      debugPrint('BillingService: Play Store Unavailable');
      return;
    }

    await _subscription?.cancel();
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseStream,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        _onErrorOccurred?.call(error.toString());
      },
    );
  }

  Future<List<SubscriptionPlan>> fetchPlans() async {
    try {
      final productDetails =
          await _purchaseManager.queryProductDetails(BillingConstants.allSkus);
      if (productDetails.isEmpty) {
        return [
          SubscriptionPlan.proMonthly,
          SubscriptionPlan.proYearly,
          SubscriptionPlan.proLifetime,
        ];
      }

      return productDetails.map((pd) {
        final planType = _mapSkuToPlanType(pd.id);
        return SubscriptionPlan(
          type: planType,
          skuId: pd.id,
          title: pd.title,
          priceFormatted: pd.price,
          periodFormatted: planType == SubscriptionPlanType.proYearly
              ? '/ year'
              : (planType == SubscriptionPlanType.proMonthly
                  ? '/ month'
                  : 'one-time'),
          badgeText: planType == SubscriptionPlanType.proYearly
              ? 'BEST VALUE'
              : (planType == SubscriptionPlanType.proLifetime
                  ? 'LIFETIME'
                  : null),
          features: _getFeaturesForType(planType),
        );
      }).toList();
    } catch (e) {
      return [
        SubscriptionPlan.proMonthly,
        SubscriptionPlan.proYearly,
        SubscriptionPlan.proLifetime,
      ];
    }
  }

  Future<void> purchasePlan(SubscriptionPlan plan) async {
    try {
      final products = await _purchaseManager.queryProductDetails({plan.skuId});
      if (products.isNotEmpty) {
        await _purchaseManager.buyProduct(products.first);
      } else {
        _onErrorOccurred?.call(BillingConstants.errItemUnavailable);
      }
    } catch (e) {
      _onErrorOccurred?.call(e.toString());
    }
  }

  Future<void> _handlePurchaseStream(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        // Pending purchase state (e.g. UPI payment processing)
      } else if (purchase.status == PurchaseStatus.canceled) {
        _onErrorOccurred?.call(BillingConstants.errPurchaseCanceled);
      } else if (purchase.status == PurchaseStatus.error) {
        _onErrorOccurred?.call(purchase.error?.message ?? 'Purchase error');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyAndDeliver(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _purchaseManager.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // ─────────────────────────────────────────────────────────────────────────
    // FINDING 2 — IAP ENTITLEMENT TRUST MODEL (Medium / Accepted Risk)
    //
    // Sagiro is a 100% on-device, serverless app.  Platform-provided receipts
    // (Google Play / App Store) are trusted here client-side, which is the
    // standard model for indie apps without a backend.
    //
    // Known risk: a determined user with root access could spoof a purchase
    // event and gain Pro entitlement without payment.
    //
    // Planned hardening (pre-scale): deploy a single Firebase Cloud Function
    // (verifyPurchase) that calls the Google Play Developer API /
    // App Store Server API to validate the purchase token before granting
    // entitlement.  See BACKEND_ARCHITECTURE.md for the Cloud Function spec.
    //
    // Until that function ships, this is an explicit and documented trade-off,
    // not an oversight.
    // ─────────────────────────────────────────────────────────────────────────
    final planType = _mapSkuToPlanType(purchase.productID);
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

    _onEntitlementUpdated?.call(entitlement);
  }

  SubscriptionPlanType _mapSkuToPlanType(String sku) {
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

  List<String> _getFeaturesForType(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.proMonthly:
        return SubscriptionPlan.proMonthly.features;
      case SubscriptionPlanType.proYearly:
        return SubscriptionPlan.proYearly.features;
      case SubscriptionPlanType.proLifetime:
        return SubscriptionPlan.proLifetime.features;
      case SubscriptionPlanType.free:
        return SubscriptionPlan.free.features;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
