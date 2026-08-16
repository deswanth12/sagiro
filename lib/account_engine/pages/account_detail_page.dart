import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/account_type.dart';
import '../services/account_intelligence_service.dart';
import '../widgets/account_insight_widget.dart';
import '../../models/transaction.dart';
import '../../theme/app_theme.dart';
import '../../components/glass_card.dart';

class AccountDetailPage extends StatelessWidget {
  final AccountModel account;
  final List<TransactionItem> allTransactions;

  const AccountDetailPage({
    super.key,
    required this.account,
    required this.allTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Filter transactions for this account
    final txs = allTransactions.where((t) {
      final accStr = (t.account ?? '').replaceAll(RegExp(r'[^\d]'), '');
      return accStr
              .endsWith(account.maskedAccountNumber.replaceAll('••••', '')) ||
          t.notes?.contains(account.bankName) == true;
    }).toList();

    final double totalIncome = txs
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final double totalOutflow = txs
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final double netFlow = totalIncome - totalOutflow;

    final insights = AccountIntelligenceService.generateRealInsights(
        account: account, accountTransactions: txs);

    // Merchant Frequency Map
    final Map<String, double> merchantSpends = {};
    for (final t in txs.where((t) => t.type == TransactionType.debit)) {
      merchantSpends[t.merchant] =
          (merchantSpends[t.merchant] ?? 0.0) + t.amount;
    }
    final topMerchants = merchantSpends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text(account.nickname,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            Text('${account.bankName} • ${account.maskedAccountNumber}',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Account Balance Header Card
            GlassCard(
              borderColor: AppTheme.electricCyan,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      account.accountType.isLiability
                          ? 'CURRENT OUTSTANDING BALANCE'
                          : 'ESTIMATED BALANCE',
                      style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(account.estimatedBalance),
                    style: TextStyle(
                      color: account.accountType.isLiability
                          ? AppTheme.dangerCoral
                          : AppTheme.electricCyan,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailStat(
                          'Total Inflow',
                          currency.format(totalIncome),
                          AppTheme.semanticSuccess),
                      _buildDetailStat('Total Outflow',
                          currency.format(totalOutflow), AppTheme.dangerCoral),
                      _buildDetailStat(
                          'Net Flow',
                          currency.format(netFlow),
                          netFlow >= 0
                              ? AppTheme.semanticSuccess
                              : AppTheme.dangerCoral),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Top Merchants
            if (topMerchants.isNotEmpty) ...[
              const Text('TOP MERCHANTS',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              ...topMerchants.take(3).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.key,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(currency.format(m.value),
                              style: const TextStyle(
                                  color: AppTheme.dangerCoral,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            // Real Money Brain Insights for Account
            const Text('ACCOUNT INTELLIGENCE INSIGHTS',
                style: TextStyle(
                    color: AppTheme.purpleGlow,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...insights.map((ins) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AccountInsightWidget(insight: ins),
                )),
            const SizedBox(height: 24),

            // Account Transactions Stream
            Text('ACCOUNT TRANSACTIONS (${txs.length})',
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            if (txs.isEmpty)
              const GlassCard(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('No transactions processed for this account yet.',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ),
              )
            else
              ...txs.take(10).map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                              t.type == TransactionType.credit
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: t.type == TransactionType.credit
                                  ? AppTheme.semanticSuccess
                                  : AppTheme.dangerCoral,
                              size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.merchant,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5)),
                                Text(
                                    DateFormat('dd MMM, yyyy • hh:mm a')
                                        .format(t.date),
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            '${t.type == TransactionType.credit ? "+" : "-"}${currency.format(t.amount)}',
                            style: TextStyle(
                              color: t.type == TransactionType.credit
                                  ? AppTheme.semanticSuccess
                                  : AppTheme.dangerCoral,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}
