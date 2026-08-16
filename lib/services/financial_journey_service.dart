import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/financial_health_timeline.dart';
import '../models/financial_achievement.dart';

class FinancialJourneyService {
  /// Generates dynamic list of 15 timeline event types from real transaction data.
  static List<FinancialTimelineItem> generateTimelineFeed({
    required List<TransactionItem> transactions,
    required double monthlyBudget,
    required double monthSpend,
  }) {
    if (transactions.isEmpty) return [];

    final List<FinancialTimelineItem> items = [];
    final now = DateTime.now();

    // Sort transactions newest first
    final sorted = List<TransactionItem>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (int i = 0; i < sorted.length && i < 15; i++) {
      final tx = sorted[i];

      // 1. Salary Credit Event
      if (tx.type == TransactionType.credit && tx.amount >= 10000) {
        items.add(FinancialTimelineItem(
          id: 'timeline_sal_${tx.id ?? i}',
          type: TimelineType.salaryReceived,
          title: 'Income Credited 💰',
          description:
              'Received ₹${tx.amount.toStringAsFixed(0)} from ${tx.merchant}',
          timestamp: tx.date,
          amount: tx.amount,
          badgeText: 'INCOME',
          icon: Icons.account_balance_wallet,
          accentColor: const Color(0xFF00E676),
        ));
      }
      // 2. Big Purchase Event (> ₹1,500)
      else if (tx.type == TransactionType.debit && tx.amount >= 1500) {
        final dayName = _getDayName(tx.date.weekday);
        items.add(FinancialTimelineItem(
          id: 'timeline_big_${tx.id ?? i}',
          type: TimelineType.bigPurchase,
          title: 'Significant Expense Alert ⚠',
          description:
              '$dayName — Spent ₹${tx.amount.toStringAsFixed(0)} at ${tx.merchant} (${tx.category})',
          timestamp: tx.date,
          amount: tx.amount,
          badgeText: 'BIG SPEND',
          icon: Icons.shopping_bag_outlined,
          accentColor: const Color(0xFFFFAB00),
        ));
      }
      // 3. Subscription Renewed / Cancelled Event
      else if (tx.category.toLowerCase().contains('sub') ||
          tx.category.toLowerCase().contains('entertain')) {
        items.add(FinancialTimelineItem(
          id: 'timeline_sub_${tx.id ?? i}',
          type: TimelineType.subscriptionRenewed,
          title: 'Subscription Processed 💸',
          description:
              '${tx.merchant} subscription debited ₹${tx.amount.toStringAsFixed(0)}',
          timestamp: tx.date,
          amount: tx.amount,
          badgeText: 'RECURRING',
          icon: Icons.autorenew,
          accentColor: const Color(0xFF00E5FF),
        ));
      }
    }

    // 4. Weekly Summary Card
    final thisWeekSpend = sorted
        .where((t) =>
            t.type == TransactionType.debit &&
            now.difference(t.date).inDays <= 7)
        .fold(0.0, (sum, t) => sum + t.amount);

    final weeklyTarget = (monthlyBudget / 4.0);
    if (thisWeekSpend > 0) {
      final isExcellent = weeklyTarget > 0
          ? thisWeekSpend <= weeklyTarget
          : thisWeekSpend < 5000;
      final savedText = weeklyTarget > thisWeekSpend
          ? 'Saved ₹${(weeklyTarget - thisWeekSpend).toStringAsFixed(0)} vs weekly pace'
          : 'Total spend ₹${thisWeekSpend.toStringAsFixed(0)}';

      items.insert(
        0,
        FinancialTimelineItem(
          id: 'timeline_week_summary',
          type: TimelineType.weeklySummary,
          title: isExcellent ? '🙂 Excellent Week' : '⚡ Active Spend Week',
          description: savedText,
          timestamp: now,
          badgeText: 'WEEKLY RECAP',
          icon: isExcellent ? Icons.sentiment_very_satisfied : Icons.bolt,
          accentColor:
              isExcellent ? const Color(0xFF00E676) : const Color(0xFFFF5252),
        ),
      );
    }

    // 5. Budget Milestone Event
    if (monthlyBudget > 0 && monthSpend > 0) {
      final pct = ((monthSpend / monthlyBudget) * 100).round();
      items.add(FinancialTimelineItem(
        id: 'timeline_budget_milestone',
        type: TimelineType.budgetReached,
        title: '🎯 Monthly Budget Pace',
        description:
            'Monthly Budget is $pct% utilized (₹${monthSpend.toStringAsFixed(0)} of ₹${monthlyBudget.toStringAsFixed(0)})',
        timestamp: now,
        badgeText: '$pct% USED',
        icon: Icons.track_changes,
        accentColor:
            pct > 100 ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
      ));
    }

    return items;
  }

  /// Calculates dynamic unlock status for 7 gamified achievement badges.
  static List<FinancialAchievement> evaluateAchievements({
    required List<TransactionItem> transactions,
    required double monthlyBudget,
    required double monthSpend,
    required int noSpendDaysCount,
  }) {
    final now = DateTime.now();

    // 1. First Week Completed
    final totalDaysTracked = transactions.isEmpty
        ? 0
        : now.difference(transactions.last.date).inDays + 1;
    final firstWeekUnlocked = totalDaysTracked >= 7;

    // 2. Saved ₹5,000
    final totalSaved =
        (monthlyBudget > monthSpend) ? (monthlyBudget - monthSpend) : 0.0;
    final saved5kUnlocked = totalSaved >= 5000;

    // 3. 30 Day Streak
    final streak30Unlocked = totalDaysTracked >= 30;

    // 4. Budget Master
    final budgetMasterUnlocked =
        monthlyBudget > 0 && monthSpend > 0 && monthSpend <= monthlyBudget;

    // 5. No Food Delivery Week (No Swiggy/Zomato in last 7 days)
    final recentFoodTxs = transactions.where((t) {
      final isRecent = now.difference(t.date).inDays <= 7;
      final m = t.merchant.toLowerCase();
      return isRecent &&
          (m.contains('swiggy') || m.contains('zomato') || m.contains('food'));
    });
    final noFoodWeekUnlocked = transactions.isNotEmpty && recentFoodTxs.isEmpty;

    // 6. Fuel Saver (Fuel spend below ₹1,500)
    final fuelSpend = transactions
        .where((t) =>
            t.date.month == now.month &&
            (t.category.toLowerCase().contains('fuel') ||
                t.merchant.toLowerCase().contains('petrol')))
        .fold(0.0, (sum, t) => sum + t.amount);
    final fuelSaverUnlocked = transactions.isNotEmpty && fuelSpend < 1500;

    // 7. Subscription Slayer (Cancelled or < 2 subscriptions)
    final subCount = transactions
        .where((t) => t.category.toLowerCase().contains('sub'))
        .length;
    final subSlayerUnlocked = subCount <= 2;

    return [
      FinancialAchievement(
        id: AchievementId.firstWeek,
        title: 'First Week Completed',
        description: 'Tracked financial habits for 7 consecutive days',
        emoji: '🏆',
        isUnlocked: firstWeekUnlocked,
        progress: (totalDaysTracked / 7.0).clamp(0.0, 1.0),
      ),
      FinancialAchievement(
        id: AchievementId.saved5k,
        title: 'Saved ₹5,000',
        description: 'Accumulated ₹5,000 in monthly savings',
        emoji: '💰',
        isUnlocked: saved5kUnlocked,
        progress: (totalSaved / 5000.0).clamp(0.0, 1.0),
      ),
      FinancialAchievement(
        id: AchievementId.streak30,
        title: '30 Day Streak',
        description: 'Maintained 30 days of active financial control',
        emoji: '🔥',
        isUnlocked: streak30Unlocked,
        progress: (totalDaysTracked / 30.0).clamp(0.0, 1.0),
      ),
      FinancialAchievement(
        id: AchievementId.budgetMaster,
        title: 'Budget Master',
        description: 'Stayed 100% within monthly budget target',
        emoji: '🎯',
        isUnlocked: budgetMasterUnlocked,
        progress: budgetMasterUnlocked
            ? 1.0
            : (monthlyBudget > 0
                ? (monthSpend / monthlyBudget).clamp(0.0, 1.0)
                : 0.0),
      ),
      FinancialAchievement(
        id: AchievementId.noFoodDeliveryWeek,
        title: 'No Food Delivery Week',
        description: '7 days without Swiggy or Zomato orders',
        emoji: '🥗',
        isUnlocked: noFoodWeekUnlocked,
        progress: noFoodWeekUnlocked ? 1.0 : 0.0,
      ),
      FinancialAchievement(
        id: AchievementId.fuelSaver,
        title: 'Fuel Saver',
        description: 'Kept monthly fuel expenses below ₹1,500',
        emoji: '🚗',
        isUnlocked: fuelSaverUnlocked,
        progress: fuelSaverUnlocked ? 1.0 : 0.5,
      ),
      FinancialAchievement(
        id: AchievementId.subscriptionSlayer,
        title: 'Subscription Slayer',
        description: 'Streamlined recurring monthly subscriptions',
        emoji: '💸',
        isUnlocked: subSlayerUnlocked,
        progress: subSlayerUnlocked ? 1.0 : 0.5,
      ),
    ];
  }

  /// Classifies monthly financial personality based on real transaction patterns.
  static String calculateFinancialPersonality(
      List<TransactionItem> transactions) {
    if (transactions.isEmpty) return 'The Planner 🎯';

    final categorySpends = <String, double>{};
    double weekendSpend = 0.0;
    double totalDebit = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.debit) {
        totalDebit += tx.amount;
        categorySpends[tx.category] =
            (categorySpends[tx.category] ?? 0.0) + tx.amount;
        if (tx.date.weekday == DateTime.saturday ||
            tx.date.weekday == DateTime.sunday) {
          weekendSpend += tx.amount;
        }
      }
    }

    if (totalDebit > 0 && (weekendSpend / totalDebit) > 0.4) {
      return 'The Weekend Spender 🥂';
    }

    final topCategory = categorySpends.entries.isEmpty
        ? ''
        : (categorySpends.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
            .toLowerCase();

    if (topCategory.contains('food') || topCategory.contains('dining')) {
      return 'The Foodie 🍕';
    } else if (topCategory.contains('shop')) {
      return 'The Impulse Buyer 🛍️';
    } else if (topCategory.contains('invest') ||
        topCategory.contains('saving')) {
      return 'The Investor 📈';
    } else if (totalDebit < 10000) {
      return 'The Saver 💰';
    }

    return 'The Budget Ninja 🥷';
  }

  /// Generates 100% data-driven real insights.
  static List<String> generateRealDataInsights(
      List<TransactionItem> transactions) {
    if (transactions.isEmpty) return [];

    final insights = <String>[];

    // 1. Food spend percentage
    final totalSpend = transactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final foodSpend = transactions
        .where((t) =>
            t.type == TransactionType.debit &&
            (t.category.toLowerCase().contains('food') ||
                t.merchant.toLowerCase().contains('swiggy')))
        .fold(0.0, (sum, t) => sum + t.amount);

    if (totalSpend > 0 && foodSpend > 0) {
      final foodPct = ((foodSpend / totalSpend) * 100).round();
      insights.add(
          'Food and dining accounts for $foodPct% of your total monthly spending.');
    }

    // 2. Weekend spend ratio
    final weekendSpend = transactions
        .where((t) =>
            t.type == TransactionType.debit &&
            (t.date.weekday == DateTime.saturday ||
                t.date.weekday == DateTime.sunday))
        .fold(0.0, (sum, t) => sum + t.amount);

    if (totalSpend > 0 && weekendSpend > 0) {
      final weekendPct = ((weekendSpend / totalSpend) * 100).round();
      insights.add(
          'Weekend expenses account for $weekendPct% of your total outlay.');
    }

    // 3. Top merchant insight
    final merchantMap = <String, double>{};
    for (final t
        in transactions.where((t) => t.type == TransactionType.debit)) {
      merchantMap[t.merchant] = (merchantMap[t.merchant] ?? 0.0) + t.amount;
    }
    if (merchantMap.isNotEmpty) {
      final topMerchant = (merchantMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first;
      insights.add(
          'Top merchant is ${topMerchant.key} totaling ₹${topMerchant.value.toStringAsFixed(0)}.');
    }

    return insights;
  }

  /// Calculates 0-100 Personal Financial Health Score based on personal habits.
  /// Zero scare tactics. Zero comparisons with others. Purely personal progress.
  static FinancialHealthResult calculateFinancialHealthScore({
    required List<TransactionItem> transactions,
    required double monthlyBudget,
    required double monthSpend,
  }) {
    if (transactions.isEmpty) {
      return const FinancialHealthResult(
        score: 85,
        ratingStars: '★★★★★',
        strengths: [
          '✓ Safe Today™ daily budget initialized',
          '✓ 100% On-Device privacy protection active',
          '✓ Ready for transaction tracking',
        ],
        focusPoints: [
          '• Add your first transaction to unlock deep habit insights.',
        ],
      );
    }

    int score = 70; // Baseline
    final List<String> strengths = [];
    final List<String> focusPoints = [];

    // 1. Budget Pacing
    if (monthlyBudget > 0) {
      if (monthSpend <= monthlyBudget) {
        score += 15;
        strengths.add('✓ Spending stays within monthly budget plan');
      } else {
        score -= 10;
        focusPoints.add('• Monthly spend is currently above planned target.');
      }
    } else {
      strengths.add('✓ Tracking daily expenses regularly');
    }

    // 2. Discretionary Control (Food/Dining ratio)
    final foodSpend = transactions
        .where((t) =>
            t.type == TransactionType.debit &&
            (t.category.toLowerCase().contains('food') ||
                t.merchant.toLowerCase().contains('swiggy') ||
                t.merchant.toLowerCase().contains('zomato')))
        .fold(0.0, (sum, t) => sum + t.amount);

    if (monthSpend > 0) {
      final foodRatio = foodSpend / monthSpend;
      if (foodRatio <= 0.25) {
        score += 10;
        strengths.add('✓ Food & dining spend kept within healthy 25% target');
      } else {
        score -= 5;
        focusPoints.add(
            '• Dining & food delivery is slightly above your target this month.');
      }
    }

    // 3. Positive Savings / Income Habits
    final incomeCredits = transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
    if (incomeCredits > 0) {
      score += 5;
      strengths.add('✓ Income and deposits tracked accurately');
    }

    final finalScore = score.clamp(30, 100);
    final stars = finalScore >= 90
        ? '★★★★★'
        : (finalScore >= 75 ? '★★★★☆' : (finalScore >= 60 ? '★★★☆☆' : '★★☆☆☆'));

    return FinancialHealthResult(
      score: finalScore,
      ratingStars: stars,
      strengths: strengths.isNotEmpty
          ? strengths
          : ['✓ Active daily expense monitoring'],
      focusPoints: focusPoints.isNotEmpty
          ? focusPoints
          : ['• Continue maintaining your daily safe spending pace.'],
    );
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Day';
    }
  }
}

class FinancialHealthResult {
  final int score;
  final String ratingStars;
  final List<String> strengths;
  final List<String> focusPoints;

  const FinancialHealthResult({
    required this.score,
    required this.ratingStars,
    required this.strengths,
    required this.focusPoints,
  });
}
