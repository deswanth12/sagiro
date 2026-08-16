import '../models/transaction.dart';

class MoneyCoachTip {
  final String title;
  final String tipText;
  final String actionableSavingsText;
  final String emoji;

  const MoneyCoachTip({
    required this.title,
    required this.tipText,
    required this.actionableSavingsText,
    required this.emoji,
  });
}

class MoneyCoachService {
  /// Generates fast, private, rule-based Money Coach advice based strictly on live transaction data.
  static List<MoneyCoachTip> generateTips({
    required List<TransactionItem> transactions,
    required double monthlyBudget,
    required double monthSpend,
  }) {
    final tips = <MoneyCoachTip>[];
    if (transactions.isEmpty) {
      return [
        const MoneyCoachTip(
          title: 'Start Tracking Spend',
          tipText: 'No transactions logged yet.',
          actionableSavingsText:
              'Add your first transaction or set a monthly budget to receive personalized AI advice.',
          emoji: '💡',
        )
      ];
    }
    final now = DateTime.now();

    // 1. Food Delivery Spend Coach Rule
    final recentFoodTxs = transactions.where((t) {
      final isRecent = now.difference(t.date).inDays <= 7;
      final m = t.merchant.toLowerCase();
      return t.type == TransactionType.debit &&
          isRecent &&
          (m.contains('swiggy') || m.contains('zomato') || m.contains('food'));
    }).toList();

    final foodSpendThisWeek =
        recentFoodTxs.fold(0.0, (sum, t) => sum + t.amount);
    if (foodSpendThisWeek >= 1000) {
      final potentialSavings = (foodSpendThisWeek * 0.35).round();
      tips.add(MoneyCoachTip(
        title: 'Food Delivery Pacing',
        tipText:
            'You spent ₹${foodSpendThisWeek.toStringAsFixed(0)} on food delivery this week across ${recentFoodTxs.length} orders.',
        actionableSavingsText:
            'Cooking at home twice would save about ₹$potentialSavings.',
        emoji: '🍕',
      ));
    }

    // 2. Subscription Savings Rule
    final subTxs = transactions.where((t) {
      return t.type == TransactionType.debit &&
          (t.category.toLowerCase().contains('sub') ||
              t.merchant.toLowerCase().contains('netflix') ||
              t.merchant.toLowerCase().contains('spotify'));
    }).toList();

    final subSpend = subTxs.fold(0.0, (sum, t) => sum + t.amount);
    if (subSpend > 500) {
      final annualSavings = (subSpend * 12 * 0.20).round();
      tips.add(MoneyCoachTip(
        title: 'Subscription Review',
        tipText:
            'Active monthly subscriptions total ₹${subSpend.toStringAsFixed(0)}/mo.',
        actionableSavingsText:
            'Switching to annual plans or cancelling unused services saves ~₹$annualSavings yearly.',
        emoji: '💸',
      ));
    }

    // 3. Weekend Spending Rule
    final weekendSpend = transactions
        .where((t) =>
            t.type == TransactionType.debit &&
            (t.date.weekday == DateTime.saturday ||
                t.date.weekday == DateTime.sunday) &&
            now.difference(t.date).inDays <= 14)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (weekendSpend >= 2500) {
      tips.add(MoneyCoachTip(
        title: 'Weekend Spike Awareness',
        tipText:
            'Weekend outings accounted for ₹${weekendSpend.toStringAsFixed(0)} over the last 2 weekends.',
        actionableSavingsText:
            'Setting a ₹1,000 weekend cap keeps your budget completely stress-free.',
        emoji: '🥂',
      ));
    }

    // 4. Default Disciplined Spender Tip
    if (tips.isEmpty) {
      tips.add(const MoneyCoachTip(
        title: 'Disciplined Pacing',
        tipText: 'Your spending discipline is top notch this week.',
        actionableSavingsText:
            'Keep maintaining your daily safe limit to build your savings reserve.',
        emoji: '🛡️',
      ));
    }

    return tips;
  }
}
