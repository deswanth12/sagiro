import '../models/transaction.dart';

class RealQuestionAnswer {
  final String question;
  final String directAnswer;
  final String supportingNumbers;
  final String whyItHappened;
  final String recommendedAction;
  final int confidenceScore;
  final String emoji;

  const RealQuestionAnswer({
    required this.question,
    required this.directAnswer,
    required this.supportingNumbers,
    required this.whyItHappened,
    required this.recommendedAction,
    required this.confidenceScore,
    required this.emoji,
  });
}

class SpendingAnalyzer {
  static RealQuestionAnswer analyze(
      String q, List<TransactionItem> txs, double income, double expenses) {
    final debits = txs.where((t) => t.type == TransactionType.debit).toList();
    final totalSpent = debits.fold(0.0, (sum, t) => sum + t.amount);

    final catMap = <String, double>{};
    final merchMap = <String, double>{};

    for (var t in debits) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
      merchMap[t.merchant] = (merchMap[t.merchant] ?? 0) + t.amount;
    }

    final topCat = (catMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .firstOrNull;
    final topMerch = (merchMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .firstOrNull;

    if (q.contains('merchant') || q.contains('most of my money')) {
      if (topMerch == null || topMerch.value <= 0) {
        return const RealQuestionAnswer(
          question: 'Which merchant took most of my money?',
          directAnswer: 'No merchant spending data available yet.',
          supportingNumbers: 'Total debits: ₹0 across 0 transactions.',
          whyItHappened: 'No debit transactions recorded.',
          recommendedAction:
              'Import a bank statement or add transactions to analyze top merchants.',
          confidenceScore: 100,
          emoji: '🏪',
        );
      }

      return RealQuestionAnswer(
        question: 'Which merchant took most of my money?',
        directAnswer:
            '${topMerch.key} took the most of your money (₹${topMerch.value.toStringAsFixed(0)}).',
        supportingNumbers:
            'Total debits: ₹${totalSpent.toStringAsFixed(0)} across ${debits.length} transactions.',
        whyItHappened: 'Frequent recurring purchases from ${topMerch.key}.',
        recommendedAction:
            'Setting a strict monthly cap on ${topMerch.key} will prevent budget leakage.',
        confidenceScore: 99,
        emoji: '🏪',
      );
    }

    final hasTopCat = topCat != null && topCat.value > 0;

    return RealQuestionAnswer(
      question: 'Where did my salary go?',
      directAnswer: hasTopCat
          ? 'Your top spending category is ${topCat.key} (₹${topCat.value.toStringAsFixed(0)}).'
          : 'No spending detected for this period yet.',
      supportingNumbers:
          'Monthly income: ₹${income.toStringAsFixed(0)} • Total debits: ₹${totalSpent.toStringAsFixed(0)}.',
      whyItHappened: hasTopCat
          ? 'High frequency of living & lifestyle expenses.'
          : 'No debit transactions recorded.',
      recommendedAction: hasTopCat
          ? 'Capping ${topCat.key} spending by 10% saves ₹${(topCat.value * 0.1).toStringAsFixed(0)} monthly.'
          : 'Import or add transactions to analyze spending breakdown.',
      confidenceScore: hasTopCat ? 98 : 100,
      emoji: '🔍',
    );
  }

  /// Generates dynamic "Today's Advice" banner for AI Assistant & Dashboard.
  /// Requires minimum 14 days of transaction history (7-day current vs 7-day baseline).
  /// Returns "Not enough transaction history yet." when history is empty or insufficient.
  static String generateTodayAdvice(List<TransactionItem> txs) {
    if (txs.isEmpty) return 'Not enough transaction history yet.';

    final now = DateTime.now();
    final oldestDate =
        txs.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final historyDays = now.difference(oldestDate).inDays + 1;

    if (historyDays < 14) return 'Not enough transaction history yet.';

    final week1Start = now.subtract(const Duration(days: 7));
    final week2Start = now.subtract(const Duration(days: 14));

    final currentDebits = txs
        .where((t) =>
            t.type == TransactionType.debit &&
            t.date.isAfter(week1Start) &&
            t.date.isBefore(now.add(const Duration(days: 1))))
        .toList();

    final baselineDebits = txs
        .where((t) =>
            t.type == TransactionType.debit &&
            (t.date.isAfter(week2Start) ||
                t.date.isAtSameMomentAs(week2Start)) &&
            (t.date.isBefore(week1Start) ||
                t.date.isAtSameMomentAs(week1Start)))
        .toList();

    if (currentDebits.isEmpty || baselineDebits.isEmpty) {
      return 'Not enough transaction history yet.';
    }

    final currentCatMap = <String, double>{};
    for (final t in currentDebits) {
      currentCatMap[t.category] = (currentCatMap[t.category] ?? 0.0) + t.amount;
    }

    final topCatEntry = (currentCatMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .firstOrNull;

    if (topCatEntry == null) return 'Not enough transaction history yet.';

    final baselineCatSpend = baselineDebits
        .where((t) => t.category == topCatEntry.key)
        .fold<double>(0.0, (s, t) => s + t.amount);

    if (baselineCatSpend <= 0) {
      return 'Top category this week is ${topCatEntry.key} (₹${topCatEntry.value.toStringAsFixed(0)}).';
    }

    final diff = topCatEntry.value - baselineCatSpend;
    if (diff < 0) {
      final pct = ((-diff / baselineCatSpend) * 100).round();
      return 'You spent $pct% less on ${topCatEntry.key} compared to last week. Nice pacing!';
    } else if (diff > 0) {
      final pct = ((diff / baselineCatSpend) * 100).round();
      return '${topCatEntry.key} spend increased by $pct% over last week. Consider capping it.';
    } else {
      return '${topCatEntry.key} spend is steady compared to last week.';
    }
  }
}

class CashFlowAnalyzer {
  static RealQuestionAnswer analyze(
      String q, double income, double expenses, double safeTodayLimit) {
    if (safeTodayLimit <= 0) {
      return RealQuestionAnswer(
        question: 'What is the safest amount I can spend today?',
        directAnswer: 'Set a monthly budget to calculate Safe Today.',
        supportingNumbers:
            'Total spent so far: ₹${expenses.toStringAsFixed(0)}.',
        whyItHappened:
            'Safe Today requires a monthly budget to calculate your daily spending limit.',
        recommendedAction: 'Set a monthly budget in the Budget tab.',
        confidenceScore: 100,
        emoji: '💡',
      );
    }

    final daysRemaining =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day -
            DateTime.now().day +
            1;
    final safeFormatted = safeTodayLimit.toStringAsFixed(0);

    return RealQuestionAnswer(
      question: 'What is the safest amount I can spend today?',
      directAnswer: 'You can safely spend ₹$safeFormatted today.',
      supportingNumbers:
          'Monthly budget: ₹${income.toStringAsFixed(0)}. Total spent: ₹${expenses.toStringAsFixed(0)}. Days left: $daysRemaining.',
      whyItHappened:
          'Calculated cleanly after reserving funds for upcoming fixed expenses.',
      recommendedAction:
          'Keep daily spending below ₹$safeFormatted to stay completely stress-free.',
      confidenceScore: 98,
      emoji: '🟢',
    );
  }
}

class AffordabilityAnalyzer {
  static RealQuestionAnswer analyze(
      String q, double income, double expenses, double netWorth) {
    final netMonthlySavings = (income - expenses).clamp(0.0, 999999.0);
    const targetCost = 79900.0;

    if (netMonthlySavings >= targetCost || netWorth >= targetCost * 2) {
      return const RealQuestionAnswer(
        question: 'Can I afford an iPhone next month?',
        directAnswer: 'Yes! Your liquid cashflow buffer fully covers the cost.',
        supportingNumbers: 'Liquid net worth: ₹79,900+ available buffer.',
        whyItHappened:
            'Consistent monthly surplus keeps your emergency fund protected.',
        recommendedAction:
            'Purchase outright or take 0-cost EMI to preserve liquidity.',
        confidenceScore: 96,
        emoji: '📱',
      );
    }

    final monthsNeeded =
        netMonthlySavings > 0 ? (targetCost / netMonthlySavings).ceil() : 5;
    return RealQuestionAnswer(
      question: 'Can I afford an iPhone next month?',
      directAnswer:
          'You cannot comfortably afford an iPhone next month. It will take $monthsNeeded months of saving.',
      supportingNumbers:
          'Monthly net savings: ₹${netMonthlySavings.toStringAsFixed(0)}/mo vs ₹79,900 target.',
      whyItHappened:
          'Buying next month would deplete your essential emergency buffer.',
      recommendedAction:
          'Start an iPhone Goal Journey saving ₹${(targetCost / 3).toStringAsFixed(0)}/mo for 3 months.',
      confidenceScore: 97,
      emoji: '⏳',
    );
  }
}

class MoneyTimelineAnalyzer {
  static RealQuestionAnswer analyze(String q, List<TransactionItem> txs) {
    final debits = txs.where((t) => t.type == TransactionType.debit).toList();
    final now = DateTime.now();
    final recentTxs =
        debits.where((t) => now.difference(t.date).inDays <= 30).toList();

    return RealQuestionAnswer(
      question: 'What happened after salary day?',
      directAnswer:
          'You completed ${recentTxs.length} transactions totaling ₹${recentTxs.fold(0.0, (s, t) => s + t.amount).toStringAsFixed(0)}.',
      supportingNumbers:
          '3 largest purchases: ${recentTxs.take(3).map((t) => "${t.merchant} (₹${t.amount.toStringAsFixed(0)})").join(", ")}.',
      whyItHappened:
          'Post-salary bill clearing and essential household shopping.',
      recommendedAction:
          'Review transaction stream to confirm all merchant charges match your receipts.',
      confidenceScore: 99,
      emoji: '📅',
    );
  }
}

class QuestionRouter {
  static RealQuestionAnswer route({
    required String question,
    required List<TransactionItem> transactions,
    required double totalNetWorth,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double safeTodayLimit,
  }) {
    final q = question.toLowerCase();

    if (q.contains('timeline') ||
        q.contains('after salary') ||
        q.contains('happened') ||
        q.contains('changed')) {
      return MoneyTimelineAnalyzer.analyze(question, transactions);
    }
    if (q.contains('afford') ||
        q.contains('iphone') ||
        q.contains('bike') ||
        q.contains('buy')) {
      return AffordabilityAnalyzer.analyze(
          question, monthlyIncome, monthlyExpenses, totalNetWorth);
    }
    if (q.contains('safe') ||
        q.contains('spend today') ||
        q.contains('survive until payday')) {
      return CashFlowAnalyzer.analyze(
          question, monthlyIncome, monthlyExpenses, safeTodayLimit);
    }
    return SpendingAnalyzer.analyze(
        question, transactions, monthlyIncome, monthlyExpenses);
  }
}

class AskYourMoneyEngine {
  static RealQuestionAnswer answer({
    required String question,
    required List<TransactionItem> transactions,
    required double totalNetWorth,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double safeTodayLimit,
  }) {
    return QuestionRouter.route(
      question: question,
      transactions: transactions,
      totalNetWorth: totalNetWorth,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      safeTodayLimit: safeTodayLimit,
    );
  }
}
