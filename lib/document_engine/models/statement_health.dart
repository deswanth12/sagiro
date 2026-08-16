class StatementHealth {
  final int healthScore; // 0 - 100%
  final int pageCount;
  final int totalTransactions;
  final bool openingBalanceVerified;
  final bool closingBalanceVerified;
  final int merchantAccuracyPercent;
  final int duplicatesRemoved;
  final String parserVersion;
  final Duration parseTime;

  const StatementHealth({
    required this.healthScore,
    required this.pageCount,
    required this.totalTransactions,
    required this.openingBalanceVerified,
    required this.closingBalanceVerified,
    required this.merchantAccuracyPercent,
    required this.duplicatesRemoved,
    required this.parserVersion,
    required this.parseTime,
  });

  bool get isHealthy => healthScore >= 80;

  String get healthBadge => isHealthy ? '🟢 Healthy (98%)' : '🟡 Needs Review';
}
