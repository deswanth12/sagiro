import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'add_transaction_dialog.dart';

class HomeWidgetGlanceCard extends StatelessWidget {
  const HomeWidgetGlanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final todayTxs = provider.transactions.where((tx) {
          final local = tx.date.toLocal();
          return local.year == now.year &&
              local.month == now.month &&
              local.day == now.day;
        }).toList();

        final double spentToday = todayTxs
            .where((tx) => tx.type == TransactionType.debit)
            .fold(0.0, (sum, tx) => sum + tx.amount);

        final double safeToday = provider.dailySafeSpendingLimit;
        final bool hasBudget = provider.hasBudget;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.electricCyan.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricCyan.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget Header Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCyan.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.widgets_rounded,
                            color: AppTheme.electricCyan, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('Android Home Screen Glance',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.semanticSuccess.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Live Widget',
                        style: TextStyle(
                            color: AppTheme.semanticSuccess,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hero Safe To Spend Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SAFE TODAY',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(
                        hasBudget ? currency.format(safeToday) : 'Set Budget',
                        style: const TextStyle(
                          color: AppTheme.semanticSuccess,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),

                  // Spent Today Sub-Stat
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('SPENT TODAY',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(spentToday),
                        style: const TextStyle(
                          color: AppTheme.dangerCoral,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Action Bar
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('＋ Add Entry',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddTransactionDialog(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
