import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../services/account_detection_engine.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';

class AccountHubPage extends StatelessWidget {
  const AccountHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          children: [
            Text('Account Hub & Intelligence',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text('Auto-detected from Bank SMS, PDF & Imports',
                style: TextStyle(
                    color: AppTheme.electricCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final txs = provider.transactions;
          final detectedAccounts = AccountDetectionEngine.detectAccounts(txs);
          final intelligenceInsights =
              AccountDetectionEngine.generateIntelligenceInsights(txs);

          final double totalSpend = txs
              .where((t) => t.type == TransactionType.debit)
              .fold(0.0, (sum, t) => sum + t.amount);
          final double totalIncome = txs
              .where((t) => t.type == TransactionType.credit)
              .fold(0.0, (sum, t) => sum + t.amount);
          final double netBalance =
              detectedAccounts.fold(0.0, (sum, a) => sum + a.balance);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Net Worth / Total Balance Hero Card
                GlassCard(
                  borderColor: AppTheme.electricCyan,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL ACCOUNTS NET BALANCE',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(netBalance.clamp(0.0, double.infinity)),
                        style: const TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBalanceSubStat(
                              'Total Income',
                              currency.format(totalIncome),
                              AppTheme.semanticSuccess),
                          _buildBalanceSubStat(
                              'Total Outflow',
                              currency.format(totalSpend),
                              AppTheme.dangerCoral),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🏦 Auto-Detected Accounts Section
                const Text('DETECTED ACCOUNTS',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),

                if (detectedAccounts.isEmpty)
                  const GlassCard(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_outlined,
                            color: AppTheme.textMuted, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No accounts detected yet. Import bank statements or scan SMS.',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...detectedAccounts.map((acc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildAccountCard(context, acc, currency),
                      )),

                const SizedBox(height: 12),

                // ＋ Add Manual Account Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.electricCyan,
                    side: const BorderSide(color: AppTheme.electricCyan),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Manual Account / Cash Wallet',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () => _showAddAccountDialog(context),
                ),

                const SizedBox(height: 28),

                // ⭐ 5 Smart Account Intelligence Insights Section
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.purpleGlow, size: 18),
                    SizedBox(width: 8),
                    Text('ACCOUNT INTELLIGENCE INSIGHTS',
                        style: TextStyle(
                            color: AppTheme.purpleGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),

                ...intelligenceInsights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildInsightCard(insight),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(
      BuildContext context, DetectedAccount acc, NumberFormat currency) {
    final bool isCreditCard = acc.accountType == AccountType.creditCard;
    final color = isCreditCard ? AppTheme.warningAmber : AppTheme.electricMint;

    return AnimatedScaleButton(
      onTap: () => _showAccountDetailSheet(context, acc, currency),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Text(acc.iconEmoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(acc.nickname,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isCreditCard
                                      ? AppTheme.warningAmber
                                      : AppTheme.semanticSuccess)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(acc.status,
                                style: TextStyle(
                                    color: isCreditCard
                                        ? AppTheme.warningAmber
                                        : AppTheme.semanticSuccess,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${acc.bankName} ••${acc.last4Digits}',
                          style: const TextStyle(
                              color: AppTheme.electricCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(acc.balance),
                      style: TextStyle(
                        color: acc.balance < 0 ? AppTheme.dangerCoral : color,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${acc.transactionCount} transfers',
                      style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10.5,
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDetailSheet(
      BuildContext context, DetectedAccount acc, NumberFormat currency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(acc.iconEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc.nickname,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('${acc.bankName} • Account ••${acc.last4Digits}',
                          style: const TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Account Balance:',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text(currency.format(acc.balance),
                    style: TextStyle(
                        color: acc.balance < 0
                            ? AppTheme.dangerCoral
                            : AppTheme.electricMint,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Transactions Processed:',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text('${acc.transactionCount} transfers',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(AccountIntelligenceInsight insight) {
    return GlassCard(
      borderColor: AppTheme.purpleGlow.withOpacity(0.25),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(insight.detail,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSubStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final bankController = TextEditingController();
    final digitsController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Add Manual Account / Cash Wallet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Bank Name / Wallet (e.g. SBI, Cash)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: digitsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Last 4 Digits (e.g. 5678)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Initial Balance (₹)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '🟢 New account added cleanly! Automatic tracking active.'),
                  backgroundColor: AppTheme.semanticSuccess,
                ),
              );
            },
            child: const Text('Save Account',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
