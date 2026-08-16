import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../services/monthly_story_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/paywall_sheet.dart';

class MonthlyStoryPage extends StatelessWidget {
  const MonthlyStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        // Pass ONLY real data: transactions and user-set monthly budget
        final story = MonthlyStoryService.generateStory(
          provider.transactions,
          provider.monthlyBudget,
        );

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: AppBar(
            title: const Text('Money Replay™ 🎬'),
            backgroundColor: AppTheme.darkBackground,
          ),
          body: story.hasData
              ? _buildStory(context, currency, story)
              : _buildEmptyState(context),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined,
                color: AppTheme.electricCyan, size: 64),
            const SizedBox(height: 20),
            Text(
              'Your Story Is Being Written',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Add transactions this month to generate your Monthly Financial Story at the end of the month.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondaryColor(context), fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStory(
      BuildContext context, NumberFormat currency, MonthlyStory story) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${story.monthYearName} Wrapped',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 28)),
          const SizedBox(height: 6),
          Text('Your monthly financial story in review',
              style: TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 13)),
          const SizedBox(height: 24),

          // Card 1: Total Spent Hero
          GlassCard(
            borderColor: AppTheme.neonMint.withOpacity(0.6),
            child: Column(
              children: [
                Text('TOTAL SPENT THIS MONTH',
                    style: TextStyle(
                        color: AppTheme.textMutedColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  currency.format(story.totalSpent),
                  style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonMint),
                ),
                // Month-over-month only shown if real comparison data exists
                if (story.monthOverMonthChangePct != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (story.isIncreaseFromLastMonth
                              ? AppTheme.dangerCoral
                              : AppTheme.successGreen)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          story.isIncreaseFromLastMonth
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: story.isIncreaseFromLastMonth
                              ? AppTheme.dangerCoral
                              : AppTheme.successGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${story.monthOverMonthChangePct!.abs().toStringAsFixed(1)}% vs last month',
                          style: TextStyle(
                            color: story.isIncreaseFromLastMonth
                                ? AppTheme.dangerCoral
                                : AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Biggest Merchant (only if real data)
          if (story.topMerchant != 'None') ...[
            GlassCard(
              borderColor: AppTheme.purpleGlow.withOpacity(0.5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppTheme.purpleGlow.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: AppTheme.purpleGlow, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BIGGEST MERCHANT',
                            style: TextStyle(
                                color: AppTheme.textMutedColor(context),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(story.topMerchant,
                            style: TextStyle(
                                color: AppTheme.textPrimaryColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(currency.format(story.topMerchantAmount),
                            style: const TextStyle(
                                color: AppTheme.purpleGlow,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFeatures: [FontFeature.tabularFigures()])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Card 3: Top Category & Peak Day Grid
          if (story.topCategory != 'None') ...[
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    borderColor: AppTheme.cyanPulse.withOpacity(0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOP CATEGORY',
                            style: TextStyle(
                                color: AppTheme.textMutedColor(context),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(story.topCategory,
                            style: TextStyle(
                                color: AppTheme.textPrimaryColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(currency.format(story.topCategoryAmount),
                            style: const TextStyle(
                                color: AppTheme.cyanPulse,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                if (story.peakSpendingDay != 'N/A') ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: GlassCard(
                      borderColor: AppTheme.amberWarning.withOpacity(0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PEAK SPEND DAY',
                              style: TextStyle(
                                  color: AppTheme.textMutedColor(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(story.peakSpendingDay,
                              style: TextStyle(
                                  color: AppTheme.textPrimaryColor(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(currency.format(story.peakDayAmount),
                              style: const TextStyle(
                                  color: AppTheme.amberWarning,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Card 4: Savings — only shown if budget is set and we have real data
          if (story.totalSaved != null) ...[
            GlassCard(
              borderColor: (story.totalSaved! >= 0
                      ? AppTheme.emeraldGreen
                      : AppTheme.dangerCoral)
                  .withOpacity(0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.totalSaved! >= 0
                            ? 'SAVED THIS MONTH'
                            : 'OVER BUDGET',
                        style: TextStyle(
                            color: AppTheme.textMutedColor(context),
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currency.format(story.totalSaved!.abs()),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: story.totalSaved! >= 0
                              ? AppTheme.emeraldGreen
                              : AppTheme.dangerCoral,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    story.totalSaved! >= 0
                        ? Icons.savings_outlined
                        : Icons.warning_amber_outlined,
                    color: story.totalSaved! >= 0
                        ? AppTheme.emeraldGreen
                        : AppTheme.dangerCoral,
                    size: 36,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Value Conversion Moment Card
          GlassCard(
            borderColor: AppTheme.electricCyan.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: AppTheme.electricCyan, size: 20),
                    const SizedBox(width: 8),
                    Text('Money Replay™ Permanent Vault',
                        style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your financial story is ready. Save every year\'s replay forever with Money Replay™ Pro.',
                  style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 12.5,
                      height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.electricCyan,
                      side: const BorderSide(color: AppTheme.electricCyan),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => PaywallSheet.showMoneyReplay(context),
                    child: const Text('Unlock Permanent Money Replay™ (₹499)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
