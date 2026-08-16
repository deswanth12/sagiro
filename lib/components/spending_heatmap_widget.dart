import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SpendingHeatmapWidget extends StatelessWidget {
  final List<TransactionItem> transactions;

  const SpendingHeatmapWidget({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    // Build map of day-offset (0 to 27) -> total spend
    final Map<int, double> dailySpends = {};

    for (int i = 0; i < 28; i++) {
      dailySpends[i] = 0.0;
    }

    for (final tx in transactions) {
      if (tx.type == TransactionType.debit) {
        final diffDays = now.difference(tx.date).inDays;
        if (diffDays >= 0 && diffDays < 28) {
          dailySpends[27 - diffDays] =
              (dailySpends[27 - diffDays] ?? 0.0) + tx.amount;
        }
      }
    }

    // Determine max spend for scaling
    final maxSpend =
        dailySpends.values.fold(0.0, (max, val) => val > max ? val : max);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = AppTheme.textSecondaryColor(context);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SPENDING HEATMAP',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text('Last 4 Weeks',
                  style: TextStyle(color: textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: 28,
            itemBuilder: (context, index) {
              final spend = dailySpends[index] ?? 0.0;
              final intensity =
                  maxSpend > 0 ? (spend / maxSpend).clamp(0.0, 1.0) : 0.0;

              Color cellColor = isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05);

              if (spend > 0) {
                if (intensity < 0.25) {
                  cellColor = AppTheme.successGreen.withOpacity(0.35);
                } else if (intensity < 0.6) {
                  cellColor = AppTheme.warningAmber.withOpacity(0.65);
                } else {
                  cellColor = AppTheme.dangerCoral.withOpacity(0.85);
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low Spend',
                  style: TextStyle(color: textSecondary, fontSize: 10)),
              const Row(
                children: [
                  _HeatmapLegendBox(color: AppTheme.successGreen),
                  SizedBox(width: 4),
                  _HeatmapLegendBox(color: AppTheme.warningAmber),
                  SizedBox(width: 4),
                  _HeatmapLegendBox(color: AppTheme.dangerCoral),
                ],
              ),
              Text('Peak Spend',
                  style: TextStyle(color: textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapLegendBox extends StatelessWidget {
  final Color color;
  const _HeatmapLegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
