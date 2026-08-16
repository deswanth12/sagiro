import '../models/transaction.dart';

class MonthlyStory {
  final String monthYearName;
  final double totalSpent;
  final String topMerchant;
  final double topMerchantAmount;
  final String topCategory;
  final double topCategoryAmount;
  final String peakSpendingDay;
  final double peakDayAmount;

  /// Real savings = monthlyBudget - totalSpent (only if budget > 0)
  final double? totalSaved;

  /// Real month-over-month percentage. Null if previous month has no data.
  final double? monthOverMonthChangePct;

  /// True if this month's spend > last month's spend
  final bool isIncreaseFromLastMonth;

  MonthlyStory({
    required this.monthYearName,
    required this.totalSpent,
    required this.topMerchant,
    required this.topMerchantAmount,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.peakSpendingDay,
    required this.peakDayAmount,
    this.totalSaved,
    this.monthOverMonthChangePct,
    required this.isIncreaseFromLastMonth,
  });

  /// Returns true if there is any data to show in this story.
  bool get hasData => totalSpent > 0;
}

class MonthlyStoryService {
  /// Generates a MonthlyStory from REAL transaction data only.
  /// Never uses hardcoded values. If data does not exist, fields are null.
  ///
  /// [monthlyBudget] — the user's set monthly budget (from settings).
  ///   If > 0, used to calculate savings = budget - spend.
  ///   If 0, savings is not shown (null).
  static MonthlyStory generateStory(
    List<TransactionItem> transactions,
    double monthlyBudget,
  ) {
    final now = DateTime.now();
    final monthName = _getMonthName(now.month);
    final monthYear = '$monthName ${now.year}';

    // ── Current month debits ──────────────────────────────────────
    final currentMonthTxs = transactions.where((tx) {
      final local = tx.date.toLocal();
      return tx.type == TransactionType.debit &&
          local.year == now.year &&
          local.month == now.month;
    }).toList();

    final double totalSpent =
        currentMonthTxs.fold(0.0, (sum, item) => sum + item.amount);

    // ── Previous month debits (for month-over-month) ──────────────
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final prevMonthTxs = transactions.where((tx) {
      final local = tx.date.toLocal();
      return tx.type == TransactionType.debit &&
          local.year == prevMonth.year &&
          local.month == prevMonth.month;
    }).toList();

    final double prevSpent =
        prevMonthTxs.fold(0.0, (sum, item) => sum + item.amount);

    // ── Month-over-month: real or null ────────────────────────────
    double? monthOverMonthChangePct;
    bool isIncrease = false;
    if (prevSpent > 0) {
      monthOverMonthChangePct = ((totalSpent - prevSpent) / prevSpent) * 100;
      isIncrease = totalSpent > prevSpent;
    }
    // If prevSpent == 0, monthOverMonthChangePct stays null → UI hides it

    // ── Top merchant ──────────────────────────────────────────────
    final Map<String, double> merchantMap = {};
    for (var tx in currentMonthTxs) {
      merchantMap[tx.merchant] = (merchantMap[tx.merchant] ?? 0) + tx.amount;
    }
    String topMerchant = 'None';
    double topMerchantAmount = 0;
    if (merchantMap.isNotEmpty) {
      final sorted = merchantMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topMerchant = sorted.first.key;
      topMerchantAmount = sorted.first.value;
    }

    // ── Top category ──────────────────────────────────────────────
    final Map<String, double> catMap = {};
    for (var tx in currentMonthTxs) {
      catMap[tx.category] = (catMap[tx.category] ?? 0) + tx.amount;
    }
    String topCat = 'None';
    double topCatAmount = 0;
    if (catMap.isNotEmpty) {
      final sorted = catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCat = sorted.first.key;
      topCatAmount = sorted.first.value;
    }

    // ── Day of week peak ──────────────────────────────────────────
    final Map<String, double> dayMap = {};
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    for (var tx in currentMonthTxs) {
      final dayName = days[tx.date.weekday - 1];
      dayMap[dayName] = (dayMap[dayName] ?? 0) + tx.amount;
    }
    String peakDay = 'N/A';
    double peakDayAmt = 0;
    if (dayMap.isNotEmpty) {
      final sorted = dayMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      peakDay = sorted.first.key;
      peakDayAmt = sorted.first.value;
    }

    // ── Savings: budget - spend (only if budget is set) ───────────
    double? totalSaved;
    if (monthlyBudget > 0 && totalSpent > 0) {
      final saved = monthlyBudget - totalSpent;
      totalSaved = saved; // Can be negative (over budget)
    }

    return MonthlyStory(
      monthYearName: monthYear,
      totalSpent: totalSpent,
      topMerchant: topMerchant,
      topMerchantAmount: topMerchantAmount,
      topCategory: topCat,
      topCategoryAmount: topCatAmount,
      peakSpendingDay: peakDay,
      peakDayAmount: peakDayAmt,
      totalSaved: totalSaved,
      monthOverMonthChangePct: monthOverMonthChangePct,
      isIncreaseFromLastMonth: isIncrease,
    );
  }

  static String _getMonthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
