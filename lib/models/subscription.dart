class SubscriptionItem {
  final String merchant;
  final double averageAmount;
  final DateTime lastBillingDate;
  final int occurrenceCount;
  final String category;
  final bool isMonthly;

  SubscriptionItem({
    required this.merchant,
    required this.averageAmount,
    required this.lastBillingDate,
    required this.occurrenceCount,
    required this.category,
    this.isMonthly = true,
  });
}
