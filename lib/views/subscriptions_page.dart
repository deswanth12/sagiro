import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/gradient_text.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final dateFormat = DateFormat('d MMM yyyy');

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final subs = provider.activeSubscriptions;
        final totalCost = provider.totalMonthlySubscriptionCost;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(
                'Subscription Detector',
                gradient: AppTheme.primaryGradient,
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                  'Auto-detected recurring payments & monthly commitments',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),

              // Total Monthly Commitment Banner
              GlassCard(
                borderColor: AppTheme.purpleGlow.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Commitment',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormat.format(totalCost),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.purpleGlow,
                              fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.purpleGlow.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.subscriptions_outlined,
                          color: AppTheme.purpleGlow, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Active Subscriptions (${subs.length})',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              subs.isEmpty
                  ? const GlassCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Icon(Icons.subscriptions_outlined,
                                  color: AppTheme.textMuted, size: 36),
                              SizedBox(height: 10),
                              Text(
                                'No recurring subscriptions detected yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Subscriptions will appear here automatically when recurring payments are detected in your transactions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subs.length,
                      itemBuilder: (context, index) {
                        final item = subs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      AppTheme.purpleGlow.withOpacity(0.2),
                                  child: Text(
                                    item.merchant[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: AppTheme.purpleGlow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.merchant,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(
                                          'Last charged ${dateFormat.format(item.lastBillingDate)}',
                                          style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${currencyFormat.format(item.averageAmount)}/mo',
                                      style: const TextStyle(
                                          color: AppTheme.neonMint,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Recurring',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 10)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }
}
