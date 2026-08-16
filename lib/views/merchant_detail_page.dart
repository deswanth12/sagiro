import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';

class MerchantDetailPage extends StatelessWidget {
  const MerchantDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final merchants = provider.topMerchants;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Merchant Intelligence',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(fontSize: 26)),
              const SizedBox(height: 6),
              const Text('Deep vendor breakdown & order habits',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              merchants.isEmpty
                  ? const GlassCard(
                      child: Center(
                        child: Text('No merchant statistics available yet.',
                            style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: merchants.length,
                      itemBuilder: (context, index) {
                        final m = merchants[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          AppTheme.cyanPulse.withOpacity(0.2),
                                      child: Text(
                                        m.merchant[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: AppTheme.cyanPulse,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(m.merchant,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17)),
                                          Text(m.primaryCategory,
                                              style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(m.totalSpent),
                                      style: const TextStyle(
                                          color: AppTheme.neonMint,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn(
                                        'Orders', '${m.orderCount} Orders'),
                                    _buildStatColumn(
                                        'Average Order',
                                        currencyFormat
                                            .format(m.averageOrderValue)),
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

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }
}
