import '../models/transaction.dart';
import '../models/money_mission.dart';

class MissionService {
  static DailyMoneyMission getTodayMission(
      List<TransactionItem> transactions, double todaySpend,
      {double dailySafeLimit = 0.0}) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;

    String id = 'mission_${now.day}_${now.month}';
    String title;
    String description;
    double targetLimit;
    String? restrictedCategory;

    final targetCap =
        dailySafeLimit > 0 ? (dailySafeLimit * 0.5).roundToDouble() : 250.0;

    // Mission logic based on day-of-week — these are guidance challenges, not fake data
    if (dayOfWeek == DateTime.friday || dayOfWeek == DateTime.saturday) {
      title = 'No Food Delivery Today';
      description = 'Skip Swiggy / Zomato orders and cook a meal at home';
      targetLimit = 0.0;
      restrictedCategory = 'Food';
    } else if (dayOfWeek == DateTime.wednesday) {
      title = 'Stay Within Travel Pacing';
      description = dailySafeLimit > 0
          ? 'Keep transport expenses under ₹${targetCap.toInt()} today'
          : 'Keep transport expenses within your daily budget';
      targetLimit = targetCap;
      restrictedCategory = 'Travel';
    } else if (dayOfWeek == DateTime.monday) {
      title = 'No Shopping Monday';
      description = 'Avoid all shopping purchases today — save it for later';
      targetLimit = 0.0;
      restrictedCategory = 'Shopping';
    } else {
      // Default daily spend challenge based on actual safe limit
      title = 'Stay In Budget Today';
      description = dailySafeLimit > 0
          ? 'Keep expenses under your daily safe limit of ₹${dailySafeLimit.toInt()}'
          : 'Set a monthly budget to calculate your daily safe limit';
      targetLimit = dailySafeLimit > 0 ? dailySafeLimit : 500.0;
      restrictedCategory = null;
    }

    // Evaluate completion from REAL transaction data
    bool completed;
    if (restrictedCategory != null) {
      final restrictedSpendToday = transactions.where((tx) {
        final local = tx.date.toLocal();
        return tx.type == TransactionType.debit &&
            tx.category == restrictedCategory &&
            local.year == now.year &&
            local.month == now.month &&
            local.day == now.day;
      }).fold(0.0, (sum, item) => sum + item.amount);
      completed = restrictedSpendToday == 0;
    } else {
      completed = todaySpend <= targetLimit;
    }

    // Calculate real streak from transaction history — consecutive days mission was achieved
    final int realStreak =
        _calculateRealStreak(transactions, targetLimit, restrictedCategory);

    return DailyMoneyMission(
      id: id,
      title: title,
      description: description,
      targetLimit: targetLimit,
      restrictedCategory: restrictedCategory,
      isCompleted: completed,
      streakDays: realStreak, // Real data, never hardcoded
    );
  }

  /// Counts consecutive past days where spending was within the mission limit
  static int _calculateRealStreak(List<TransactionItem> transactions,
      double limit, String? restrictedCategory) {
    if (transactions.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;

    for (int daysBack = 1; daysBack <= 30; daysBack++) {
      final checkDate = now.subtract(Duration(days: daysBack));

      final dayTransactions = transactions.where((tx) {
        final local = tx.date.toLocal();
        return tx.type == TransactionType.debit &&
            local.year == checkDate.year &&
            local.month == checkDate.month &&
            local.day == checkDate.day;
      });

      double dayTotal;
      if (restrictedCategory != null) {
        dayTotal = dayTransactions
            .where((tx) => tx.category == restrictedCategory)
            .fold(0.0, (s, tx) => s + tx.amount);
        if (dayTotal == 0) {
          streak++;
        } else {
          break;
        }
      } else {
        dayTotal = dayTransactions.fold(0.0, (s, tx) => s + tx.amount);
        if (dayTotal <= limit) {
          streak++;
        } else {
          break;
        }
      }
    }

    return streak;
  }
}
