class MoneyHealthScore {
  final int overallScore; // 0-100
  final int savingsScore; // 0-100
  final int subscriptionScore; // 0-100
  final int impulseControlScore; // 0-100
  final int budgetAdherenceScore; // 0-100

  MoneyHealthScore({
    required this.overallScore,
    required this.savingsScore,
    required this.subscriptionScore,
    required this.impulseControlScore,
    required this.budgetAdherenceScore,
  });

  String get ratingText {
    if (overallScore >= 80) return 'Excellent Financial Health 🌟';
    if (overallScore >= 60) return 'Good - Room for Optimization 👍';
    if (overallScore >= 40) return 'Fair - Watch Your Impulse Spend ⚠️';
    return 'Needs Attention 🚨';
  }
}
