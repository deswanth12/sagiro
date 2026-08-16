enum RiskLevel { low, moderate, high }

class BudgetForecast {
  final double currentSpend;
  final double monthlyBudget;
  final double predictedMonthEnd;
  final double dailyVelocity;
  final int daysElapsed;
  final int totalDaysInMonth;
  final RiskLevel riskLevel;

  BudgetForecast({
    required this.currentSpend,
    required this.monthlyBudget,
    required this.predictedMonthEnd,
    required this.dailyVelocity,
    required this.daysElapsed,
    required this.totalDaysInMonth,
    required this.riskLevel,
  });

  bool get isOverBudget =>
      predictedMonthEnd > monthlyBudget && monthlyBudget > 0;
  double get overspendAmount =>
      isOverBudget ? (predictedMonthEnd - monthlyBudget) : 0.0;
}
