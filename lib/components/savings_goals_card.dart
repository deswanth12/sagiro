import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SavingsGoalsCard extends StatelessWidget {
  final List<SavingsGoal> goals;
  final VoidCallback onAddGoal;

  const SavingsGoalsCard({
    super.key,
    required this.goals,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_outlined,
                      color: AppTheme.successGreen, size: 18),
                  SizedBox(width: 8),
                  Text('SAVINGS GOALS',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_circle_outline,
                    color: AppTheme.electricCyan, size: 20),
                onPressed: onAddGoal,
                tooltip: 'Add Savings Goal',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Real Data or Clean Empty State (Zero Fake Data) ──────────
          if (goals.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    const Icon(Icons.savings_outlined,
                        color: AppTheme.textMuted, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No savings goals set yet',
                      style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set targets for an Emergency Fund, Vacation, or Tech purchase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onPressed: onAddGoal,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Savings Goal',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...goals.map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(goal.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(goal.title,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                        Text(
                          '${currency.format(goal.currentAmount)} / ${currency.format(goal.targetAmount)}',
                          style: const TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.successGreen),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          goal.isCompleted
                              ? '🎉 You reached your ${goal.title}! Saved ${currency.format(goal.targetAmount)}.'
                              : '${goal.progressPct}% Saved',
                          style: TextStyle(
                            color: goal.isCompleted
                                ? AppTheme.semanticSuccess
                                : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: goal.isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text('Pace: ${currency.format(goal.monthlyNeeded)}/mo',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
