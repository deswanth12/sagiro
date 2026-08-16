import 'subscription_plan.dart';

class PremiumEntitlement {
  final SubscriptionPlanType planType;
  final String? purchaseToken;
  final String? firebaseUid;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final bool isEntitled;
  final bool isInGracePeriod;

  const PremiumEntitlement({
    required this.planType,
    this.purchaseToken,
    this.firebaseUid,
    this.purchaseDate,
    this.expiryDate,
    required this.isEntitled,
    this.isInGracePeriod = false,
  });

  static const PremiumEntitlement free = PremiumEntitlement(
    planType: SubscriptionPlanType.free,
    isEntitled: false,
  );

  bool get isActive {
    if (!isEntitled) return false;
    if (planType == SubscriptionPlanType.proLifetime) return true;
    if (expiryDate == null) return false;
    return DateTime.now().isBefore(expiryDate!);
  }

  Map<String, dynamic> toJson() => {
        'planType': planType.index,
        'purchaseToken': purchaseToken,
        'firebaseUid': firebaseUid,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'isEntitled': isEntitled,
        'isInGracePeriod': isInGracePeriod,
      };

  factory PremiumEntitlement.fromJson(Map<String, dynamic> json) {
    final rawIndex = json['planType'] as int? ?? 0;
    final planType =
        (rawIndex >= 0 && rawIndex < SubscriptionPlanType.values.length)
            ? SubscriptionPlanType.values[rawIndex]
            : SubscriptionPlanType.free;
    return PremiumEntitlement(
      planType: planType,
      purchaseToken: json['purchaseToken'],
      firebaseUid: json['firebaseUid'],
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isEntitled: json['isEntitled'] ?? false,
      isInGracePeriod: json['isInGracePeriod'] ?? false,
    );
  }
}
