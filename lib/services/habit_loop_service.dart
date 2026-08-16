import '../models/transaction.dart';
import '../models/habit_loop.dart';
import 'financial_journey_service.dart';

class HabitLoopService {
  static MoneyWeatherForecast getWeatherForecast({
    required double todaySpend,
    required double dailySafeLimit,
    required double predictedMonthEnd,
    required double monthlyBudget,
    required bool hasTransactions,
  }) {
    // No data — neutral state, never assume anything
    if (!hasTransactions) {
      return MoneyWeatherForecast(
        status: 'Getting Started 🌅',
        riskText: 'Awaiting Data',
        safeAmount: dailySafeLimit,
        tip:
            'Add your first transaction or scan your bank SMS inbox to get a personalized forecast.',
      );
    }

    // 1. 🌪 Financial Storm — Budget exceeded
    if (monthlyBudget > 0 && predictedMonthEnd > monthlyBudget * 1.15) {
      return MoneyWeatherForecast(
        status: 'Financial Storm 🌪️',
        riskText: 'Budget Exceeded Risk',
        safeAmount: dailySafeLimit,
        tip:
            'Monthly budget threshold exceeded. Slow down non-essential spending immediately.',
      );
    }

    // 2. ⛈ Heavy Spending — Today exceeds safe limit significantly
    if (dailySafeLimit > 0 && todaySpend > dailySafeLimit * 1.25) {
      return MoneyWeatherForecast(
        status: 'Heavy Spending ⛈️',
        riskText: 'Slow Down Warning',
        safeAmount: dailySafeLimit,
        tip:
            'Today\'s expenses exceeded your daily safe limit. Freeze discretionary spending for the rest of today.',
      );
    }

    // 3. 🌦 Watchful — Approaching budget limit
    if (monthlyBudget > 0 && predictedMonthEnd > monthlyBudget * 0.85) {
      return MoneyWeatherForecast(
        status: 'Watchful 🌦️',
        riskText: 'Approaching Budget',
        safeAmount: dailySafeLimit,
        tip:
            'You are approaching 85% of your monthly budget limit. Stay mindful of weekend expenses.',
      );
    }

    // 4. 🌤 Stable — On Track
    if (todaySpend > 0 && todaySpend <= dailySafeLimit) {
      return MoneyWeatherForecast(
        status: 'Stable 🌤️',
        riskText: 'On Track',
        safeAmount: dailySafeLimit,
        tip:
            'Spending is well-paced today. You are staying right inside your daily target.',
      );
    }

    // 5. ☀ Sunny — Spending strictly under control
    return MoneyWeatherForecast(
      status: 'Sunny ☀️',
      riskText: 'Under Control',
      safeAmount: dailySafeLimit,
      tip: 'Outstanding discipline! Zero or very low spending recorded today.',
    );
  }

  static SpendingPersonality getPersonality(
      Map<String, double> categoryBreakdown,
      List<TransactionItem> transactions) {
    final title =
        FinancialJourneyService.calculateFinancialPersonality(transactions);
    return SpendingPersonality(
      title: title,
      description: 'Calculated from your live transaction spending patterns.',
      iconEmoji: title.split(' ').last,
    );
  }

  static DailyWin getDailyWin(double todaySpend, double dailySafeLimit) {
    final isWin = todaySpend <= dailySafeLimit;
    final saved =
        dailySafeLimit > todaySpend ? (dailySafeLimit - todaySpend) : 0.0;
    return DailyWin(
      amountSavedUnderSafeLimit: saved,
      isWin: isWin,
      message: isWin
          ? 'You kept today\'s spend within your target limit!'
          : 'Exceeded daily safe limit. Slow down tomorrow.',
    );
  }

  static int getNoSpendDaysCount(List<TransactionItem> transactions) {
    return calculateNoSpendDaysCount(transactions);
  }

  static int calculateNoSpendDaysCount(List<TransactionItem> transactions) {
    if (transactions.isEmpty) return 0;
    final now = DateTime.now();
    final currentMonthTxs = transactions.where((t) {
      final local = t.date.toLocal();
      return local.year == now.year && local.month == now.month;
    }).toList();

    final daysWithSpend =
        currentMonthTxs.map((t) => t.date.toLocal().day).toSet();
    final totalDaysPassed = now.day;

    return (totalDaysPassed - daysWithSpend.length).clamp(0, 31);
  }

  static int calculateNoSpendStreak(List<TransactionItem> transactions) {
    if (transactions.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final hasSpendOnDate = transactions.any(
        (t) {
          final local = t.date.toLocal();
          return t.type == TransactionType.debit &&
              local.year == checkDate.year &&
              local.month == checkDate.month &&
              local.day == checkDate.day;
        },
      );

      if (!hasSpendOnDate) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
