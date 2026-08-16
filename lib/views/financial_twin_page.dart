import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../services/financial_twin_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/paywall_sheet.dart';

class FinancialTwinPage extends StatelessWidget {
  const FinancialTwinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.transactions.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor(context),
            appBar: AppBar(
              title: const Text('Financial DNA™ Simulator 🔮'),
              backgroundColor: AppTheme.backgroundColor(context),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology_outlined,
                        color: AppTheme.electricCyan, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'Analytics will appear after your first transaction.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Simulate habit changes and compounding wealth after recording your spending.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final realFoodSpend = provider.categoryBreakdown['Food'] ?? 0.0;
        final realSavings = (provider.monthlyBudget - provider.monthSpend)
            .clamp(0.0, double.infinity);

        final scenarios = FinancialTwinService.generateScenarios(
          currentFoodDeliverySpend: realFoodSpend,
          currentSubscriptionSpend: provider.totalMonthlySubscriptionCost,
          currentMonthlySavings: realSavings,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Financial DNA™ Simulator 🔮'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What-If Wealth Simulator',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                    'Simulate small habit changes to see long-term wealth impact',
                    style:
                        TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 13)),
                const SizedBox(height: 24),
                ...scenarios.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      borderColor: AppTheme.neonMint.withOpacity(0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: AppTheme.neonMint.withOpacity(0.15),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.bolt,
                                    color: AppTheme.neonMint, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(s.title,
                                    style: TextStyle(
                                        color: AppTheme.textPrimaryColor(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(s.description,
                              style: TextStyle(
                                  color: AppTheme.textSecondaryColor(context), fontSize: 13)),
                          const SizedBox(height: 16),
                          Divider(color: AppTheme.borderColor(context)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('1-Year Projected Savings',
                                      style: TextStyle(
                                          color: AppTheme.textMutedColor(context),
                                          fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(currency.format(s.oneYearProjection),
                                      style: const TextStyle(
                                          color: AppTheme.neonMint,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ])),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('5-Year Compound Value',
                                      style: TextStyle(
                                          color: AppTheme.textMutedColor(context),
                                          fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(currency.format(s.fiveYearProjection),
                                      style: const TextStyle(
                                          color: AppTheme.cyanPulse,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ])),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // Value Conversion Moment Card
                GlassCard(
                  borderColor: AppTheme.electricCyan.withOpacity(0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology,
                              color: AppTheme.electricCyan, size: 20),
                          const SizedBox(width: 8),
                          Text('Financial DNA™ Lifetime Insights',
                              style: TextStyle(
                                  color: AppTheme.textPrimaryColor(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ve unlocked your financial personality. Get deeper behavioral wealth insights with Pro.',
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
                            side:
                                const BorderSide(color: AppTheme.electricCyan),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () =>
                              PaywallSheet.showFinancialDna(context),
                          child: const Text('Unlock Financial DNA™ Pro (₹499)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
