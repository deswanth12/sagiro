import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SafeTodayExplanationSheet extends StatelessWidget {
  final double safeTodayLimit;
  final double spentToday;
  final double monthSpent;
  final double monthlyBudget;
  final String? upcomingBillTitle;
  final double? upcomingBillAmount;

  const SafeTodayExplanationSheet({
    super.key,
    required this.safeTodayLimit,
    required this.spentToday,
    required this.monthSpent,
    required this.monthlyBudget,
    this.upcomingBillTitle,
    this.upcomingBillAmount,
  });

  static void show(
    BuildContext context, {
    required double safeTodayLimit,
    required double spentToday,
    required double monthSpent,
    required double monthlyBudget,
    String? upcomingBillTitle,
    double? upcomingBillAmount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeTodayExplanationSheet(
        safeTodayLimit: safeTodayLimit,
        spentToday: spentToday,
        monthSpent: monthSpent,
        monthlyBudget: monthlyBudget,
        upcomingBillTitle: upcomingBillTitle,
        upcomingBillAmount: upcomingBillAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingMonthBudget =
        (monthlyBudget - monthSpent).clamp(0.0, 500000.0);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (daysInMonth - now.day + 1).clamp(1, 31);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final cardBg = AppTheme.cardColor(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
            top: BorderSide(color: AppTheme.electricCyan, width: 1.5)),
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
                  color: textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: AppTheme.electricCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why did my Safe Today change?',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    const Text('Explainability for your peace of mind',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s Safe Limit',
                        style: TextStyle(color: textSecondary, fontSize: 13)),
                    Text('₹${safeTodayLimit.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.electricCyan,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildFactorRow(context, 'Remaining Monthly Plan',
                    '₹${remainingMonthBudget.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildFactorRow(
                    context, 'Days Left in Month', '$daysRemaining days'),
                const SizedBox(height: 8),
                _buildFactorRow(context, 'Spent So Far Today',
                    '₹${spentToday.toStringAsFixed(0)}'),
                if (upcomingBillTitle != null &&
                    upcomingBillAmount != null) ...[
                  const SizedBox(height: 8),
                  _buildFactorRow(context, 'Reserved for $upcomingBillTitle',
                      '₹${upcomingBillAmount!.toStringAsFixed(0)}',
                      isHighlight: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.semanticSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.semanticSuccess.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.semanticSuccess, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nothing is wrong. Your plan automatically adjusts every day so you never run out before payday.',
                    style: TextStyle(
                        color: textPrimary, fontSize: 12, height: 1.35),
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
              child: const Text('Got it',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow(BuildContext context, String label, String value,
      {bool isHighlight = false}) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color:
                      isHighlight ? AppTheme.warningAmber : AppTheme.textMuted,
                  fontSize: 12.5,
                  fontWeight:
                      isHighlight ? FontWeight.bold : FontWeight.normal)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                color: isHighlight ? AppTheme.warningAmber : textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
