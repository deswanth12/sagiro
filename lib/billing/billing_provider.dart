import 'package:flutter/foundation.dart';
import 'billing_service.dart';
import 'billing_state.dart';
import 'restore_purchase_service.dart';
import 'subscription_manager.dart';
import 'models/subscription_plan.dart';
import 'models/premium_entitlement.dart';

class BillingProvider extends ChangeNotifier {
  final BillingService _billingService;
  final SubscriptionManager _subscriptionManager;
  final RestorePurchaseService _restoreService;

  BillingState _state = const BillingState(
    status: BillingStatus.initial,
    entitlement: PremiumEntitlement.free,
    availablePlans: [],
  );

  BillingState get state => _state;
  bool get isPro => _state.isPro;
  PremiumEntitlement get entitlement => _state.entitlement;
  BillingStatus get status => _state.status;
  List<SubscriptionPlan> get plans => _state.availablePlans;
  String? get errorMessage => _state.errorMessage;

  BillingProvider({
    BillingService? billingService,
    SubscriptionManager? subscriptionManager,
    RestorePurchaseService? restoreService,
  })  : _billingService = billingService ?? BillingService(),
        _subscriptionManager = subscriptionManager ?? SubscriptionManager(),
        _restoreService = restoreService ?? RestorePurchaseService() {
    _init();
  }

  Future<void> _init() async {
    _state = _state.copyWith(status: BillingStatus.loading);
    notifyListeners();

    try {
      await _subscriptionManager.initialize();
      _state =
          _state.copyWith(entitlement: _subscriptionManager.currentEntitlement);

      await _billingService.initialize(
        onEntitlementUpdated: (newEntitlement) async {
          await _subscriptionManager.setEntitlement(newEntitlement);
          _state = _state.copyWith(
            status: BillingStatus.success,
            entitlement: newEntitlement,
          );
          notifyListeners();
        },
        onErrorOccurred: (err) {
          _state = _state.copyWith(
            status: BillingStatus.error,
            errorMessage: err,
          );
          notifyListeners();
        },
      );

      final plans = await _billingService.fetchPlans();
      _state = _state.copyWith(
        status: BillingStatus.available,
        availablePlans: plans,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: BillingStatus.error,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> purchasePlan(SubscriptionPlan plan) async {
    _state = _state.copyWith(status: BillingStatus.purchasing);
    notifyListeners();
    try {
      await _billingService.purchasePlan(plan);
    } catch (e) {
      _state = _state.copyWith(
        status: BillingStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _state = _state.copyWith(status: BillingStatus.loading);
    notifyListeners();
    try {
      final restored = await _restoreService.restorePurchases();
      await _subscriptionManager.setEntitlement(restored);
      _state = _state.copyWith(
        status: restored.isActive
            ? BillingStatus.restored
            : BillingStatus.available,
        entitlement: restored,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: BillingStatus.error,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }
}
