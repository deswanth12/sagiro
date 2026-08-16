class FinancialHealthScore {
  final int overallScore; // 0 to 100
  final String ratingText; // e.g. "Excellent Financial Health"
  final double budgetAdherenceScore; // 0 to 25
  final double savingsRateScore; // 0 to 20
  final double discretionaryRatioScore; // 0 to 15
  final double subscriptionBurdenScore; // 0 to 10
  final double dailyConsistencyScore; // 0 to 15
  final double noSpendDaysScore; // 0 to 15

  const FinancialHealthScore({
    required this.overallScore,
    required this.ratingText,
    required this.budgetAdherenceScore,
    required this.savingsRateScore,
    required this.discretionaryRatioScore,
    required this.subscriptionBurdenScore,
    required this.dailyConsistencyScore,
    required this.noSpendDaysScore,
  });

  static FinancialHealthScore calculate({
    required double monthSpend,
    required double monthlyBudget,
    required int totalTransactions,
    required int noSpendDays,
    required int totalSubscriptionCount,
    required double foodSpend,
  }) {
    // 1. Budget Adherence (25 pts)
    double budgetScore = 25.0;
    if (monthlyBudget > 0) {
      final pct = monthSpend / monthlyBudget;
      if (pct > 1.0) {
        budgetScore = (25.0 - ((pct - 1.0) * 50.0)).clamp(0.0, 25.0);
      } else {
        budgetScore = (25.0 * (1.0 - (pct * 0.2))).clamp(15.0, 25.0);
      }
    }

    // 2. Savings Rate Score (20 pts)
    double savingsScore = 15.0;
    if (monthlyBudget > 0 && monthSpend < monthlyBudget) {
      final savedRatio = (monthlyBudget - monthSpend) / monthlyBudget;
      savingsScore = (savedRatio * 20.0).clamp(10.0, 20.0);
    }

    // 3. Discretionary / Food ratio (15 pts)
    double foodScore = 15.0;
    if (monthSpend > 0) {
      final foodRatio = foodSpend / monthSpend;
      if (foodRatio > 0.4) {
        foodScore = (15.0 - ((foodRatio - 0.4) * 20.0)).clamp(5.0, 15.0);
      }
    }

    // 4. Subscription Burden (10 pts)
    double subScore = 10.0;
    if (totalSubscriptionCount > 4) {
      subScore = (10.0 - (totalSubscriptionCount - 4) * 1.5).clamp(3.0, 10.0);
    }

    // 5. Daily Consistency (15 pts)
    double consistencyScore = 12.0;
    if (totalTransactions > 0) {
      consistencyScore = 15.0;
    }

    // 6. No spend days (15 pts)
    double noSpendScore = (noSpendDays * 3.0).clamp(0.0, 15.0);

    final total = (budgetScore +
            savingsScore +
            foodScore +
            subScore +
            consistencyScore +
            noSpendScore)
        .round()
        .clamp(0, 100);

    String rating = 'Excellent Financial Health';
    if (total < 60) {
      rating = 'Needs Focus & Budget Guard';
    } else if (total < 75) {
      rating = 'Moderate Financial Health';
    } else if (total < 90) {
      rating = 'Strong Financial Discipline';
    }

    return FinancialHealthScore(
      overallScore: total,
      ratingText: rating,
      budgetAdherenceScore: budgetScore,
      savingsRateScore: savingsScore,
      discretionaryRatioScore: foodScore,
      subscriptionBurdenScore: subScore,
      dailyConsistencyScore: consistencyScore,
      noSpendDaysScore: noSpendScore,
    );
  }
}
