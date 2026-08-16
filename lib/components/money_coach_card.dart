import 'package:flutter/material.dart';
import '../services/money_coach_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class MoneyCoachCard extends StatelessWidget {
  final List<MoneyCoachTip> tips;

  const MoneyCoachCard({
    super.key,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();
    final topTip = tips.first;

    return GlassCard(
      borderColor: AppTheme.warningAmber.withOpacity(0.4),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(topTip.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('MONEY COACH',
                  style: TextStyle(
                      color: AppTheme.warningAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(topTip.title,
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text(topTip.tipText,
              style: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                  fontSize: 13,
                  height: 1.4)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppTheme.warningAmber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    topTip.actionableSavingsText,
                    style: const TextStyle(
                        color: AppTheme.warningAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
