import '../models/account_model.dart';
import '../models/account_type.dart';
import '../models/account_insight.dart';
import '../../models/transaction.dart';

class AccountIntelligenceService {
  /// Generates dynamic, strictly real account insights from transactions
  static List<AccountInsight> generateRealInsights({
    required AccountModel account,
    required List<TransactionItem> accountTransactions,
  }) {
    final List<AccountInsight> insights = [];
    final now = DateTime.now();

    if (accountTransactions.isEmpty) {
      insights.add(AccountInsight(
        id: 'ins_empty_${account.id}',
        accountId: account.id,
        type: InsightType.accountInactivity,
        emoji: 'ℹ️',
        title: 'New Account Registered',
        detail:
            'No transactions processed for ${account.nickname} yet. Sync SMS or import statement to see live insights.',
        generatedAt: now,
      ));
      return insights;
    }

    // 1. Salary Credit Pattern
    final salaryTxs = accountTransactions
        .where((t) =>
            t.category.toLowerCase() == 'salary' ||
            t.merchant.toLowerCase().contains('salary'))
        .toList();
    if (salaryTxs.isNotEmpty) {
      final salaryTx = salaryTxs.first;
      insights.add(AccountInsight(
        id: 'ins_sal_${account.id}',
        accountId: account.id,
        type: InsightType.salaryPattern,
        emoji: '💼',
        title: 'Primary Salary Account',
        detail:
            'Most of your salary (₹${salaryTx.amount.toStringAsFixed(0)}) arrives in ${account.bankName} on day ${salaryTx.date.day} of every month.',
        generatedAt: now,
      ));
    }

    // 2. UPI Spend Ratio
    final upiTxs = accountTransactions
        .where((t) =>
            t.merchant.toLowerCase().contains('upi') ||
            (t.notes?.toLowerCase().contains('upi') ?? false))
        .toList();
    if (upiTxs.isNotEmpty) {
      final pct = ((upiTxs.length / accountTransactions.length) * 100).round();
      insights.add(AccountInsight(
        id: 'ins_upi_${account.id}',
        accountId: account.id,
        type: InsightType.upiUsage,
        emoji: '📱',
        title: 'UPI Payment Hub',
        detail:
            '$pct% of your daily UPI spending originates from ${account.nickname}.',
        generatedAt: now,
      ));
    }

    // 3. Credit Card Outflow Status
    if (account.accountType.isLiability) {
      final totalDebt = accountTransactions
          .where((t) => t.type == TransactionType.debit)
          .fold<double>(0.0, (s, t) => s + t.amount);
      insights.add(AccountInsight(
        id: 'ins_crd_${account.id}',
        accountId: account.id,
        type: InsightType.creditCardSpend,
        emoji: '💳',
        title: 'Monthly Card Outflow',
        detail:
            'You spent ₹${totalDebt.toStringAsFixed(0)} using your credit card this month.',
        generatedAt: now,
      ));
    }

    // 4. Inactivity Detection (90 days)
    final lastTx = account.lastTransactionDate ??
        (accountTransactions.isNotEmpty
            ? accountTransactions.first.date
            : null);
    if (lastTx != null && now.difference(lastTx).inDays >= 90) {
      insights.add(AccountInsight(
        id: 'ins_inact_${account.id}',
        accountId: account.id,
        type: InsightType.accountInactivity,
        emoji: '⏸️',
        title: 'Account Inactivity Alert',
        detail:
            'This account has been inactive for ${now.difference(lastTx).inDays} days.',
        generatedAt: now,
      ));
    }

    return insights;
  }
}
