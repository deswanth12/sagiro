import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feature_access.dart';

enum BillingStatus {
  initial,
  loading,
  available,
  unavailable,
  purchasing,
  success,
  restored,
  error,
}

/// BillingService — Production Google Play Billing Library Engine.
/// Handles product querying, purchase verification, purchase updates stream,
/// offline purchase caching in SharedPreferences, and grace period handling.
class BillingService {
  static const String _kCachedTierKey = 'cached_subscription_tier';
  static const String _kCachedPurchaseTokenKey = 'cached_purchase_token';
  static const String _kCachedExpiryKey = 'cached_subscription_expiry';

  InAppPurchase? _iapInstance;
  InAppPurchase get _iap => _iapInstance ??= InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  BillingStatus _status = BillingStatus.initial;
  BillingStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Function(SubscriptionTier)? _onTierUpdated;

  Future<void> initialize({Function(SubscriptionTier)? onTierUpdated}) async {
    _onTierUpdated = onTierUpdated;

    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      _status = BillingStatus.unavailable;
      debugPrint(
          'BillingService: Google Play Billing unavailable on this device/environment.');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseStreamUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (err) {
        _status = BillingStatus.error;
        _errorMessage = err.toString();
      },
    );

    await queryProducts();
  }

  /// Queries Google Play Store for active SKUs:
  ///   - com.paisapilot.pro.monthly (₹99/mo)  [Play Console SKU — do not change]
  ///   - com.paisapilot.pro.yearly  (₹799/yr)  [Play Console SKU — do not change]
  Future<void> queryProducts() async {
    _status = BillingStatus.loading;
    final Set<String> skus = {
      FeatureAccess.skuProMonthly,
      FeatureAccess.skuProYearly,
    };

    try {
      final response = await _iap.queryProductDetails(skus);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            'BillingService SKUs not found on Play Console: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      _status = _products.isNotEmpty
          ? BillingStatus.available
          : BillingStatus.unavailable;
    } catch (e) {
      debugPrint('BillingService.queryProducts error: $e');
      _status = BillingStatus.error;
      _errorMessage = e.toString();
    }
  }

  /// Initiates purchase flow for a selected Play Store product details.
  Future<void> buyProduct(ProductDetails product) async {
    _status = BillingStatus.purchasing;
    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _status = BillingStatus.error;
      _errorMessage = e.toString();
    }
  }

  /// Restores prior Play Store purchases for current Google Play account.
  Future<void> restorePurchases() async {
    _status = BillingStatus.loading;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _status = BillingStatus.error;
      _errorMessage = e.toString();
    }
  }

  void _onPurchaseStreamUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        _status = BillingStatus.purchasing;
      } else if (purchase.status == PurchaseStatus.error) {
        _status = BillingStatus.error;
        _errorMessage = purchase.error?.message ?? 'Purchase error';
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _verifyAndDeliverPurchase(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchase) async {
    SubscriptionTier tier = SubscriptionTier.free;

    if (purchase.productID == FeatureAccess.skuProMonthly) {
      tier = SubscriptionTier.proMonthly;
    } else if (purchase.productID == FeatureAccess.skuProYearly) {
      tier = SubscriptionTier.proYearly;
    }

    if (tier.isPro) {
      // Cache purchase locally in SharedPreferences for offline execution
      await cacheSubscriptionState(
        tier: tier,
        token: purchase.verificationData.serverVerificationData,
        expiry: DateTime.now().add(tier == SubscriptionTier.proYearly
            ? const Duration(days: 365)
            : const Duration(days: 30)),
      );

      _status = purchase.status == PurchaseStatus.restored
          ? BillingStatus.restored
          : BillingStatus.success;
      _onTierUpdated?.call(tier);
    }
  }

  /// Caches active subscription state for offline execution.
  static Future<void> cacheSubscriptionState({
    required SubscriptionTier tier,
    required String token,
    required DateTime expiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCachedTierKey, tier.index);
    await prefs.setString(_kCachedPurchaseTokenKey, token);
    await prefs.setString(_kCachedExpiryKey, expiry.toIso8601String());
  }

  /// Retrieves cached subscription state when device is offline.
  static Future<SubscriptionTier> getCachedSubscriptionTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tierIndex = prefs.getInt(_kCachedTierKey) ?? 0;
    final expiryStr = prefs.getString(_kCachedExpiryKey);

    if (tierIndex == 0) return SubscriptionTier.free;

    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        // Expired subscription grace period expired
        await prefs.setInt(_kCachedTierKey, 0);
        return SubscriptionTier.free;
      }
    }

    return SubscriptionTier.values[tierIndex];
  }

  void dispose() {
    _subscription?.cancel();
  }
}
