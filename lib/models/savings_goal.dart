class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String emoji;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.emoji,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  int get progressPct => (progress * 100).round();
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, targetAmount);
  bool get isCompleted => targetAmount > 0 && currentAmount >= targetAmount;

  double get monthlyNeeded {
    final now = DateTime.now();
    final monthsLeft =
        ((targetDate.year - now.year) * 12 + targetDate.month - now.month);
    if (monthsLeft <= 0) return remainingAmount;
    return remainingAmount / monthsLeft;
  }
}
