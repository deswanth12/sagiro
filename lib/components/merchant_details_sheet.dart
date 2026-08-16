import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class MerchantDetailsSheet extends StatelessWidget {
  final String merchantName;
  final int transactionCount;
  final double monthlyTotal;
  final double yearlyTotal;
  final double averageOrderValue;
  final String trendComparison;
  final String moneyBrainInsight;

  const MerchantDetailsSheet({
    super.key,
    required this.merchantName,
    required this.transactionCount,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.averageOrderValue,
    required this.trendComparison,
    required this.moneyBrainInsight,
  });

  static void show(
    BuildContext context, {
    required String merchantName,
    required int transactionCount,
    required double monthlyTotal,
    required double yearlyTotal,
    required double averageOrderValue,
    required String trendComparison,
    required String moneyBrainInsight,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MerchantDetailsSheet(
        merchantName: merchantName,
        transactionCount: transactionCount,
        monthlyTotal: monthlyTotal,
        yearlyTotal: yearlyTotal,
        averageOrderValue: averageOrderValue,
        trendComparison: trendComparison,
        moneyBrainInsight: moneyBrainInsight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: AppTheme.electricCyan, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppTheme.electricCyan, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(merchantName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('$transactionCount transactions tracked',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GlassCard(
            borderColor: AppTheme.electricCyan.withOpacity(0.2),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatColumn(
                        'This Month', '₹${monthlyTotal.toStringAsFixed(0)}'),
                    _buildStatColumn(
                        'This Year', '₹${yearlyTotal.toStringAsFixed(0)}'),
                    _buildStatColumn('Avg Order',
                        '₹${averageOrderValue.toStringAsFixed(0)}'),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: AppTheme.warningAmber, size: 16),
                    const SizedBox(width: 8),
                    Text(trendComparison,
                        style: const TextStyle(
                            color: AppTheme.warningAmber,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Money Brain Insight Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.electricCyan.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_outlined,
                    color: AppTheme.electricCyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MONEY BRAIN INSIGHT',
                          style: TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text(moneyBrainInsight,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.35)),
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
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
