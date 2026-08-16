import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/gradient_text.dart';
import '../components/achievement_badge_card.dart';
import '../components/add_transaction_dialog.dart';
import '../components/sms_scan_result_sheet.dart';
import '../services/financial_journey_service.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final transactions = provider.transactions;
        final monthSpend = provider.monthSpend;
        final monthlyBudget = provider.monthlyBudget;
        final noSpendDays = provider.noSpendDaysCount;

        if (transactions.isEmpty) {
          return const _InsightsEmptyState();
        }

        // Calculate 0-100 Personal Financial Health Score (No scare tactics)
        final healthResult =
            FinancialJourneyService.calculateFinancialHealthScore(
          transactions: transactions,
          monthlyBudget: monthlyBudget,
          monthSpend: monthSpend,
        );

        // Evaluate Achievements
        final achievements = FinancialJourneyService.evaluateAchievements(
          transactions: transactions,
          monthlyBudget: monthlyBudget,
          monthSpend: monthSpend,
          noSpendDaysCount: noSpendDays,
        );

        // Financial Personality
        final personality =
            FinancialJourneyService.calculateFinancialPersonality(transactions);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(
                'Financial Health & Journey',
                gradient: AppTheme.mintGradient,
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('Personal progress tracking • Zero scare tactics',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),

              // 🏆 0-100 Personal Financial Health Score Card
              GlassCard(
                borderColor: AppTheme.electricCyan.withOpacity(0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PERSONAL FINANCIAL HEALTH',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            personality,
                            style: const TextStyle(
                                color: AppTheme.electricCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${healthResult.score}',
                          style: const TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                        const Text(' / 100',
                            style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          healthResult.ratingStars,
                          style: const TextStyle(
                              color: AppTheme.warningAmber, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: healthResult.score / 100.0,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.electricCyan),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // Strengths List
                    const Text('Strengths',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...healthResult.strengths.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(s,
                              style: const TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 12.5)),
                        )),
                    const SizedBox(height: 10),

                    // Focus Points List
                    const Text('Focus Area',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...healthResult.focusPoints.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(f,
                              style: const TextStyle(
                                  color: AppTheme.warningAmber,
                                  fontSize: 12.5)),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 🏅 Financial Achievements Badges
              AchievementBadgeCard(achievements: achievements),
              const SizedBox(height: 18),

              // 📊 Monthly Spend Summary Header
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THIS MONTH SUMMARY',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currency.format(monthSpend),
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('${transactions.length} total transactions',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$noSpendDays Days',
                                style: const TextStyle(
                                    color: AppTheme.successGreen,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const Text('No-Spend Streak',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InsightsEmptyState extends StatelessWidget {
  const _InsightsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.electricCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_outlined,
                  color: AppTheme.electricCyan, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Your financial story starts today.',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first expense or import your bank SMS to unlock your Financial Health Score, Achievements, and Journey Timeline.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Expense',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddTransactionDialog(),
                    );
                  },
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.electricCyan,
                    side: const BorderSide(color: AppTheme.electricCyan),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.sms_rounded, size: 18),
                  label: const Text('Scan SMS',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SmsScanResultSheet(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
