import 'dart:math';

class WhatIfScenario {
  final String title;
  final String description;
  final double monthlySavingsDelta;
  final double oneYearProjection;
  final double fiveYearProjection;

  WhatIfScenario({
    required this.title,
    required this.description,
    required this.monthlySavingsDelta,
    required this.oneYearProjection,
    required this.fiveYearProjection,
  });
}

class FinancialTwinService {
  /// Calculates Future Value of a Monthly SIP assuming 12% annual return (1% monthly).
  static double calculateSipFutureValue(double monthlyAmount, int months,
      {double annualReturnRate = 0.12}) {
    if (monthlyAmount <= 0 || months <= 0) return 0.0;
    final r = annualReturnRate / 12.0;
    final fv = monthlyAmount * ((pow(1 + r, months) - 1) / r) * (1 + r);
    return fv;
  }

  static List<WhatIfScenario> generateScenarios({
    required double currentFoodDeliverySpend,
    required double currentSubscriptionSpend,
    required double currentMonthlySavings,
  }) {
    final List<WhatIfScenario> scenarios = [];

    // Scenario 1: Cut Food Delivery in half
    final cutFoodMonthly = currentFoodDeliverySpend * 0.5;
    if (cutFoodMonthly > 0) {
      scenarios.add(WhatIfScenario(
        title: 'Reduce Swiggy / Zomato by 50%',
        description: 'Order 2-3 fewer times per month and cook home meals',
        monthlySavingsDelta: cutFoodMonthly,
        oneYearProjection: cutFoodMonthly * 12,
        fiveYearProjection: calculateSipFutureValue(cutFoodMonthly, 60),
      ));
    }

    // Scenario 2: Increase SIP Investment by ₹2,000
    const sipIncrease = 2000.0;
    scenarios.add(WhatIfScenario(
      title: 'Increase Monthly SIP by ₹2,000',
      description: 'Auto-invest ₹2,000 into Nifty 50 Index Fund',
      monthlySavingsDelta: sipIncrease,
      oneYearProjection: sipIncrease * 12,
      fiveYearProjection: calculateSipFutureValue(sipIncrease, 60),
    ));

    // Scenario 3: Cancel unused subscriptions
    final subCutMonthly = currentSubscriptionSpend * 0.4;
    if (subCutMonthly > 0) {
      scenarios.add(WhatIfScenario(
        title: 'Audit & Trim Subscriptions',
        description: 'Cancel 2 under-utilized streaming or app memberships',
        monthlySavingsDelta: subCutMonthly,
        oneYearProjection: subCutMonthly * 12,
        fiveYearProjection: calculateSipFutureValue(subCutMonthly, 60),
      ));
    }

    return scenarios;
  }
}
