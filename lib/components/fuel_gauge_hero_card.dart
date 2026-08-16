import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'animated_count_up.dart';
import 'safe_today_explanation_sheet.dart';

/// FuelGaugeHeroCard — "Safe Today" Mission Control Hero Widget.
/// Crafted with huge typography, animated count-up, ambient fuel indicator,
/// explainability info drawer, and "Safe Until Payday" calculation.
class FuelGaugeHeroCard extends StatelessWidget {
  final double dailySafeLimit;
  final double todaySpend;
  final double monthlyBudget;
  final double monthSpend;
  final VoidCallback? onWhyTap;

  const FuelGaugeHeroCard({
    super.key,
    required this.dailySafeLimit,
    required this.todaySpend,
    required this.monthlyBudget,
    required this.monthSpend,
    this.onWhyTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    final remainingSafeToday =
        (dailySafeLimit - todaySpend).clamp(0.0, double.infinity);

    final gaugePct = dailySafeLimit > 0
        ? (remainingSafeToday / dailySafeLimit).clamp(0.0, 1.0)
        : 0.0;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysUntilPayday = (daysInMonth - now.day + 1).clamp(1, 31);

    final isSafe = gaugePct >= 0.3;
    final statusColor =
        isSafe ? AppTheme.semanticSuccess : AppTheme.semanticDanger;
    if (dailySafeLimit <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.crispBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SAFE TODAY',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Set a monthly budget to calculate Safe Today',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Establishes your daily spending buffer automatically.',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SAFE TODAY',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (onWhyTap != null) {
                    onWhyTap!();
                  } else {
                    SafeTodayExplanationSheet.show(
                      context,
                      safeTodayLimit: dailySafeLimit,
                      spentToday: todaySpend,
                      monthSpent: monthSpend,
                      monthlyBudget: monthlyBudget,
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Details',
                    style: TextStyle(
                      color: AppTheme.semanticInfo,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedCountUp(
              value: remainingSafeToday,
              prefix: '₹',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Available today',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: gaugePct,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${currencyFormat.format(todaySpend)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '$daysUntilPayday days left',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
