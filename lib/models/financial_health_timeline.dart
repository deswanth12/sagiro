import 'package:flutter/material.dart';

enum TimelineType {
  dailyWin,
  weeklySummary,
  monthlySummary,
  bigPurchase,
  subscriptionRenewed,
  subscriptionCancelled,
  noSpendDay,
  streakStarted,
  streakBroken,
  categorySpike,
  salaryReceived,
  budgetReached,
  goalCompleted,
  insight,
  achievementUnlocked,
}

class FinancialTimelineItem {
  final String id;
  final TimelineType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final double? amount;
  final String? badgeText;
  final IconData icon;
  final Color accentColor;

  const FinancialTimelineItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.amount,
    this.badgeText,
    required this.icon,
    required this.accentColor,
  });
}
