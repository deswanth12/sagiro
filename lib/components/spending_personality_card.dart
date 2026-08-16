import 'package:flutter/material.dart';
import '../models/habit_loop.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SpendingPersonalityCard extends StatelessWidget {
  final SpendingPersonality personality;
  final int noSpendDays;

  const SpendingPersonalityCard({
    super.key,
    required this.personality,
    required this.noSpendDays,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.purpleGlow.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.purpleGlow.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Text(personality.iconEmoji,
                style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SPENDING PERSONALITY',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  personality.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  personality.description,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌱 No-Spend',
                    style: TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('$noSpendDays Days',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
