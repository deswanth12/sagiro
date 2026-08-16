import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class WhySafeTodaySheet extends StatelessWidget {
  final BudgetProvider provider;

  const WhySafeTodaySheet({
    super.key,
    required this.provider,
  });

  static void show(BuildContext context, BudgetProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhySafeTodaySheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (totalDaysInMonth - now.day + 1).clamp(1, 31);

    final monthlyBudget = provider.monthlyBudget;
    final monthSpend = provider.monthSpend;
    final todaySpend = provider.todaySpend;

    final upcomingBillsTotal = provider.upcomingBills
        .where((b) => !b.isPaid)
        .fold<double>(0.0, (s, b) => s + b.amount);

    final savingsGoalsTotal =
        provider.savingsGoals.fold<double>(0.0, (s, g) => s + g.currentAmount);

    final availableBuffer = provider.availableBuffer;
    final safeToday = provider.dailySafeSpendingLimit;

    final pacesDifference = todaySpend - safeToday;
    final isOverPace = pacesDifference > 0;    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border:
            const Border(top: BorderSide(color: AppTheme.electricCyan, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle & Title
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Safe Today?',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete mathematical transparency for today\'s ₹${safeToday.toStringAsFixed(0)} limit',
                      style: const TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: AppTheme.textMutedColor(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step-by-Step Mathematical Calculation Card
            GlassCard(
              borderColor: AppTheme.electricCyan.withOpacity(0.3),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildMathRow(context, 'Monthly Budget / Income',
                      currency.format(monthlyBudget), AppTheme.electricMint),
                  _buildMathRow(context, 'Already Spent (This Month)',
                      '-${currency.format(monthSpend)}', AppTheme.dangerCoral),
                  if (upcomingBillsTotal > 0)
                    _buildMathRow(
                        context,
                        'Upcoming Bills Committed',
                        '-${currency.format(upcomingBillsTotal)}',
                        AppTheme.warningAmber),
                  if (savingsGoalsTotal > 0)
                    _buildMathRow(
                        context,
                        'Savings Goals Reserved',
                        '-${currency.format(savingsGoalsTotal)}',
                        AppTheme.purpleGlow),
                  Divider(color: AppTheme.borderColor(context), height: 20),
                  _buildMathRow(context, 'Available Remaining Buffer',
                      currency.format(availableBuffer), AppTheme.textPrimaryColor(context),
                      isBold: true),
                  _buildMathRow(context, 'Days Remaining in Month',
                      '$daysRemaining days', AppTheme.electricCyan),
                  Divider(color: AppTheme.borderColor(context), height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SAFE TODAY LIMIT',
                        style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        currency.format(safeToday),
                        style: const TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Yesterday vs Today Comparison Card
            GlassCard(
              borderColor: AppTheme.electricMint.withOpacity(0.3),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.compare_arrows_rounded,
                          color: AppTheme.electricMint, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'WHY DID THIS CHANGE?',
                        style: TextStyle(
                          color: AppTheme.electricMint,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yesterday',
                              style: TextStyle(
                                  color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                          Text(
                            currency.format(safeToday + todaySpend),
                            style: TextStyle(
                                color: AppTheme.textPrimaryColor(context),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_rounded,
                          color: AppTheme.textMutedColor(context), size: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Today',
                              style: TextStyle(
                                  color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                          Text(
                            currency.format(safeToday),
                            style: const TextStyle(
                                color: AppTheme.electricMint,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: AppTheme.borderColor(context), height: 20),
                  Text(
                    todaySpend > 0
                        ? '• Spent ${currency.format(todaySpend)} today'
                        : '• No spending recorded yet today',
                    style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ${provider.transactions.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day).length} transactions recorded today',
                    style: TextStyle(
                        color: AppTheme.textSecondaryColor(context), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data Quality Confidence Notice (User Spec: Evaluate structural signals)
            if (monthlyBudget <= 0 ||
                (provider.transactions.isNotEmpty &&
                    now
                            .difference(
                                provider.transactions.first.date.toLocal())
                            .inHours >
                        48)) ...[
              GlassCard(
                borderColor: AppTheme.warningAmber,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.warningAmber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        monthlyBudget <= 0
                            ? 'Your estimate has lower confidence because monthly budget is not configured.'
                            : 'Your estimate has lower confidence because transactions haven\'t updated recently.',
                        style: const TextStyle(
                            color: AppTheme.warningAmber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Explanatory Contextual Intelligence Card (User Rule 2: "Your Safe Today dropped ₹120 today because...")
            GlassCard(
              borderColor:
                  isOverPace ? AppTheme.warningAmber : AppTheme.semanticSuccess,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isOverPace
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isOverPace
                        ? AppTheme.warningAmber
                        : AppTheme.semanticSuccess,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOverPace
                              ? 'Budget Pace Insight'
                              : 'Smooth Budget Velocity',
                          style: TextStyle(
                            color: isOverPace
                                ? AppTheme.warningAmber
                                : AppTheme.semanticSuccess,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOverPace
                              ? 'Your Safe Today pace adjusted by ₹${pacesDifference.toStringAsFixed(0)} today because spending was higher than usual. Remaining buffer is automatically re-balanced over the next $daysRemaining days.'
                              : 'You are spending comfortably within plan. Your ₹${safeToday.toStringAsFixed(0)} daily limit keeps your financial buffer safe until month end.',
                          style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Understood • Close',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathRow(BuildContext context, String label, String value, Color valueColor,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? AppTheme.textPrimaryColor(context) : AppTheme.textSecondaryColor(context),
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
