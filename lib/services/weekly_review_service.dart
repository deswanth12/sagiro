import '../models/transaction.dart';
import '../models/upcoming_bill.dart';

class WeeklyReviewReport {
  final double weeklySpent;
  final double weeklySaved;
  final String bestDecision;
  final String nextWeekOutlook;
  final int confidenceScore;
  final List<String> confidencePillars;
  final String gentleRecommendation;

  WeeklyReviewReport({
    required this.weeklySpent,
    required this.weeklySaved,
    required this.bestDecision,
    required this.nextWeekOutlook,
    required this.confidenceScore,
    required this.confidencePillars,
    required this.gentleRecommendation,
  });
}

class WeeklyReviewService {
  /// Calculates real Sunday Morning Weekly Review using exact 7-day vs previous 7-day baseline
  static WeeklyReviewReport generateWeeklyReview(
    List<TransactionItem> transactions, {
    List<UpcomingBill> upcomingBills = const [],
    double monthlyBudget = 0.0,
    double safeTodayLimit = 0.0,
  }) {
    final now = DateTime.now();
    final week1Start = now.subtract(const Duration(days: 7));
    final week2Start = now.subtract(const Duration(days: 14));

    // Current 7 days: (t - 7 to t)
    final currentPeriodTxs = transactions
        .where((t) =>
            t.date.isAfter(week1Start) &&
            t.date.isBefore(now.add(const Duration(days: 1))))
        .toList();

    // Baseline 7 days: (t - 14 to t - 7)
    final baselinePeriodTxs = transactions
        .where((t) =>
            t.date.isAfter(week2Start) &&
            (t.date.isBefore(week1Start) ||
                t.date.isAtSameMomentAs(week1Start)))
        .toList();

    final currentDebits =
        currentPeriodTxs.where((t) => t.type == TransactionType.debit).toList();
    final baselineDebits = baselinePeriodTxs
        .where((t) => t.type == TransactionType.debit)
        .toList();

    final weeklySpent = currentDebits.fold<double>(0.0, (s, t) => s + t.amount);
    final weeklyIncome = currentPeriodTxs
        .where((t) => t.type == TransactionType.credit)
        .fold<double>(0.0, (s, t) => s + t.amount);
    final weeklySaved =
        (weeklyIncome - weeklySpent).clamp(0.0, double.infinity);

    // 1. Upcoming Bills Outlook
    final activeBills =
        upcomingBills.where((b) => b.isActive && !b.isPaid).toList();
    final String nextWeekOutlook;
    if (activeBills.isEmpty) {
      nextWeekOutlook = 'No upcoming bills';
    } else {
      final billSummaries = activeBills
          .take(2)
          .map((b) => '${b.title} (₹${b.amount.toStringAsFixed(0)})')
          .join(' • ');
      nextWeekOutlook = 'Upcoming fixed bills: $billSummaries';
    }

    // 2. Category Comparison / Recommendation Rule:
    // Requires sufficient data in BOTH periods (at least 1 debit in each period).
    final String gentleRecommendation;
    if (currentDebits.isEmpty || baselineDebits.isEmpty) {
      gentleRecommendation = 'Not enough spending data yet';
    } else {
      // Find top spending category in current 7 days
      final currentCatMap = <String, double>{};
      for (final tx in currentDebits) {
        currentCatMap[tx.category] =
            (currentCatMap[tx.category] ?? 0.0) + tx.amount;
      }
      final topCurrent = (currentCatMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .firstOrNull;

      if (topCurrent == null) {
        gentleRecommendation = 'Not enough spending data yet';
      } else {
        // Compare with same category in baseline 7 days
        final baselineCatSpend = baselineDebits
            .where((t) => t.category == topCurrent.key)
            .fold<double>(0.0, (s, t) => s + t.amount);

        if (baselineCatSpend > 0) {
          final diff = topCurrent.value - baselineCatSpend;
          if (diff > 0) {
            final pct = ((diff / baselineCatSpend) * 100).round();
            gentleRecommendation =
                '${topCurrent.key} spend increased by $pct% (₹${diff.toStringAsFixed(0)}) over last week.';
          } else if (diff < 0) {
            final pct = ((-diff / baselineCatSpend) * 100).round();
            gentleRecommendation =
                'Great job! ${topCurrent.key} spend decreased by $pct% compared to last week.';
          } else {
            gentleRecommendation =
                '${topCurrent.key} spend is steady compared to last week.';
          }
        } else {
          gentleRecommendation =
              'Top category this week: ${topCurrent.key} (₹${topCurrent.value.toStringAsFixed(0)}).';
        }
      }
    }

    // 3. Best decision summary
    final String bestDecision = currentDebits.isEmpty
        ? 'No debit transactions recorded this week.'
        : 'Tracked ${currentDebits.length} transactions totaling ₹${weeklySpent.toStringAsFixed(0)}.';

    // 4. Confidence calculation based on budget adherence
    int confidence = 95;
    if (monthlyBudget > 0 && weeklySpent > monthlyBudget) confidence -= 15;
    if (currentDebits.isEmpty) confidence = 85;

    final pillars = <String>[];
    if (activeBills.isNotEmpty) {
      pillars.add('• Active upcoming bills tracked: ${activeBills.length}');
    } else {
      pillars.add('• No upcoming bills pending');
    }

    if (safeTodayLimit > 0) {
      pillars.add(
          '• Safe Today limit active: ₹${safeTodayLimit.toStringAsFixed(0)}');
    } else {
      pillars.add('• Set a monthly budget to calculate Safe Today');
    }

    if (currentDebits.isNotEmpty) {
      pillars
          .add('• 7-day spending pacing: ₹${weeklySpent.toStringAsFixed(0)}');
    } else {
      pillars.add('• Zero debits recorded this week');
    }

    return WeeklyReviewReport(
      weeklySpent: weeklySpent,
      weeklySaved: weeklySaved,
      bestDecision: bestDecision,
      nextWeekOutlook: nextWeekOutlook,
      confidenceScore: confidence.clamp(70, 100),
      confidencePillars: pillars,
      gentleRecommendation: gentleRecommendation,
    );
  }
}
