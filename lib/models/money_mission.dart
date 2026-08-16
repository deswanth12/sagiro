class DailyMoneyMission {
  final String id;
  final String title;
  final String description;
  final double targetLimit; // e.g., 400.0 or category cap
  final String? restrictedCategory; // e.g. "Food" for no food delivery
  final bool isCompleted;
  final int streakDays;

  DailyMoneyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.targetLimit,
    this.restrictedCategory,
    required this.isCompleted,
    required this.streakDays,
  });
}
