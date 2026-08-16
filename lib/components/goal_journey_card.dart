import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class GoalJourneyCard extends StatelessWidget {
  final SavingsGoal goal;

  const GoalJourneyCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final remaining =
        (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
    final estMonths = remaining > 0 ? (remaining / 5000).ceil() : 0;
    final estCompletionDate =
        DateTime.now().add(Duration(days: estMonths * 30));

    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.3),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('GOAL JOURNEY',
                    style: TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Emotional Milestone Journey Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildJourneyStep('Started', 'January'),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.textMuted, size: 14),
              _buildJourneyStep('Saved', currency.format(goal.currentAmount)),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.textMuted, size: 14),
              _buildJourneyStep('Remaining', currency.format(remaining)),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.textMuted, size: 14),
              _buildJourneyStep(
                  'Expected', DateFormat('MMM dd').format(estCompletionDate)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: goal.progress,
            backgroundColor: AppTheme.darkCard,
            color: AppTheme.electricCyan,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}
