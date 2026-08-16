import 'models/premium_entitlement.dart';
import 'models/subscription_plan.dart';

enum BillingStatus {
  initial,
  loading,
  available,
  unavailable,
  purchasing,
  success,
  restored,
  canceled,
  error,
}

class BillingState {
  final BillingStatus status;
  final PremiumEntitlement entitlement;
  final List<SubscriptionPlan> availablePlans;
  final String? errorMessage;

  const BillingState({
    required this.status,
    required this.entitlement,
    required this.availablePlans,
    this.errorMessage,
  });

  bool get isPro => entitlement.isActive;

  BillingState copyWith({
    BillingStatus? status,
    PremiumEntitlement? entitlement,
    List<SubscriptionPlan>? availablePlans,
    String? errorMessage,
  }) {
    return BillingState(
      status: status ?? this.status,
      entitlement: entitlement ?? this.entitlement,
      availablePlans: availablePlans ?? this.availablePlans,
      errorMessage: errorMessage,
    );
  }
}
