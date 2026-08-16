import '../models/transaction.dart';
import '../models/budget_forecast.dart';

class BudgetForecastService {
  static BudgetForecast calculateForecast(
      List<TransactionItem> transactions, double monthlyBudget) {
    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day == 0 ? 1 : now.day;

    // Filter current month debit transactions
    double currentSpend = 0.0;
    for (final tx in transactions) {
      final local = tx.date.toLocal();
      if (tx.type == TransactionType.debit &&
          local.year == now.year &&
          local.month == now.month) {
        currentSpend += tx.amount;
      }
    }

    final dailyVelocity = currentSpend / daysElapsed;
    final predictedMonthEnd = dailyVelocity * totalDaysInMonth;

    RiskLevel risk = RiskLevel.low;
    if (monthlyBudget > 0) {
      final ratio = predictedMonthEnd / monthlyBudget;
      if (ratio > 1.15) {
        risk = RiskLevel.high;
      } else if (ratio > 0.90) {
        risk = RiskLevel.moderate;
      }
    }

    return BudgetForecast(
      currentSpend: currentSpend,
      monthlyBudget: monthlyBudget,
      predictedMonthEnd: predictedMonthEnd,
      dailyVelocity: dailyVelocity,
      daysElapsed: daysElapsed,
      totalDaysInMonth: totalDaysInMonth,
      riskLevel: risk,
    );
  }
}
