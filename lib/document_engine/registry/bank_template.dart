class BankTemplate {
  final String bankId;
  final String bankName;
  final String version;
  final List<String> headerKeywords;
  final RegExp? debitRegex;
  final RegExp? creditRegex;
  final RegExp? balanceRegex;
  final RegExp? merchantRegex;

  const BankTemplate({
    required this.bankId,
    required this.bankName,
    required this.version,
    required this.headerKeywords,
    this.debitRegex,
    this.creditRegex,
    this.balanceRegex,
    this.merchantRegex,
  });

  bool matchesHeader(String headerText) {
    final lower = headerText.toLowerCase();
    return headerKeywords.any((kw) => lower.contains(kw.toLowerCase()));
  }
}
