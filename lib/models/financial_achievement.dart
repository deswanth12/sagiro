enum AchievementId {
  firstWeek,
  saved5k,
  streak30,
  budgetMaster,
  noFoodDeliveryWeek,
  fuelSaver,
  subscriptionSlayer,
}

class FinancialAchievement {
  final AchievementId id;
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0

  const FinancialAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0.0,
  });

  FinancialAchievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
  }) {
    return FinancialAchievement(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }
}
