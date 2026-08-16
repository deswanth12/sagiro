import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/feature_access.dart';
import '../services/billing_service.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final BillingService _billingService = BillingService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  SubscriptionTier get currentTier => _subscriptionService.currentTier;
  bool get isPro => currentTier.isPro;

  BillingStatus get status => _billingService.status;
  List<ProductDetails> get products => _billingService.products;
  String? get errorMessage => _billingService.errorMessage;

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    await _subscriptionService.initialize();
    await _billingService.initialize(
      onTierUpdated: (newTier) {
        _subscriptionService.setTier(newTier);
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails product) async {
    await _subscriptionService.trackUpgradeAttempt();
    await _billingService.buyProduct(product);
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    await _billingService.restorePurchases();
    notifyListeners();
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }
}
