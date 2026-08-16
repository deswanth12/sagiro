enum InsightType {
  salaryPattern,
  upiUsage,
  creditCardSpend,
  merchantPreference,
  accountInactivity,
  savingsGrowth,
}

class AccountInsight {
  final String id;
  final String accountId;
  final InsightType type;
  final String emoji;
  final String title;
  final String detail;
  final DateTime generatedAt;

  AccountInsight({
    required this.id,
    required this.accountId,
    required this.type,
    required this.emoji,
    required this.title,
    required this.detail,
    required this.generatedAt,
  });
}
