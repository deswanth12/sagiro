import 'package:flutter/material.dart';
import '../models/money_mission.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class DailyMissionCard extends StatelessWidget {
  final DailyMoneyMission mission;

  const DailyMissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        mission.isCompleted ? AppTheme.electricMint : AppTheme.warningAmber;

    return GlassCard(
      borderColor: statusColor.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.military_tech_outlined,
                        color: AppTheme.electricMint, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Daily Money Mission',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mission.isCompleted ? 'COMPLETED 🎉' : 'IN PROGRESS',
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                    if (mission.isCompleted && mission.streakDays > 0) ...[
                      const SizedBox(width: 4),
                      Text('• ${mission.streakDays}🔥',
                          style: const TextStyle(
                              color: AppTheme.warningAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mission.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            mission.description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
