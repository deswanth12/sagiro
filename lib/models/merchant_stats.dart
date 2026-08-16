class MerchantStats {
  final String merchant;
  final double totalSpent;
  final int orderCount;
  final double averageOrderValue;
  final String primaryCategory;
  final DateTime lastTransactionDate;

  MerchantStats({
    required this.merchant,
    required this.totalSpent,
    required this.orderCount,
    required this.averageOrderValue,
    required this.primaryCategory,
    required this.lastTransactionDate,
  });
}
