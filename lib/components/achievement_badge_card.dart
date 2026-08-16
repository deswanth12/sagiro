import 'package:flutter/material.dart';
import '../models/financial_achievement.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class AchievementBadgeCard extends StatelessWidget {
  final List<FinancialAchievement> achievements;

  const AchievementBadgeCard({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events,
                        color: AppTheme.warningAmber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Achievements',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlockedCount / ${achievements.length} Unlocked',
                  style: const TextStyle(
                      color: AppTheme.warningAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final ach = achievements[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ach.isUnlocked
                      ? AppTheme.electricCyan.withOpacity(0.08)
                      : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ach.isUnlocked
                        ? AppTheme.electricCyan.withOpacity(0.4)
                        : Colors.white10,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ach.emoji,
                          style: TextStyle(fontSize: ach.isUnlocked ? 24 : 20),
                        ),
                        Icon(
                          ach.isUnlocked
                              ? Icons.check_circle
                              : Icons.lock_outline,
                          color: ach.isUnlocked
                              ? AppTheme.electricCyan
                              : Colors.white30,
                          size: 16,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ach.title,
                          style: TextStyle(
                            color: ach.isUnlocked
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ach.description,
                          style: TextStyle(
                              color: AppTheme.textMuted.withOpacity(0.7),
                              fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ach.progress,
                        minHeight: 3,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ach.isUnlocked
                              ? AppTheme.electricCyan
                              : AppTheme.warningAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
