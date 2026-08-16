import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';

class SpendingHeatmap extends StatelessWidget {
  final List<TransactionItem> transactions;

  const SpendingHeatmap({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final Map<int, double> dayTotals = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0
    };

    final now = DateTime.now();
    for (var tx in transactions) {
      final local = tx.date.toLocal();
      if (tx.type == TransactionType.debit &&
          local.year == now.year &&
          local.month == now.month) {
        final w = local.weekday;
        dayTotals[w] = (dayTotals[w] ?? 0) + tx.amount;
      }
    }

    final maxVal =
        dayTotals.values.fold<double>(1.0, (max, v) => v > max ? v : max);

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      color: AppTheme.amberWarning, size: 20),
                  SizedBox(width: 8),
                  Text('Weekly Spending Heatmap',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppTheme.amberWarning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Peak Habits',
                    style: TextStyle(
                        color: AppTheme.amberWarning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final amt = dayTotals[dayNum] ?? 0;
              final heightPct = (amt / maxVal).clamp(0.12, 1.0);
              final isPeak = amt == maxVal && amt > 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amt > 0 ? currency.format(amt) : '₹0',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                      color: isPeak ? AppTheme.neonMint : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 90 * heightPct,
                    width: 22,
                    decoration: BoxDecoration(
                      color: isPeak
                          ? AppTheme.neonMint
                          : (amt > 0
                              ? AppTheme.cyanPulse.withOpacity(0.4)
                              : AppTheme.darkBackground),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPeak ? AppTheme.neonMint : Colors.white10,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      color: isPeak ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
