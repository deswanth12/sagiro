class TransactionProvenance {
  final String origin; // PDF, Excel, CSV, OCR, SMS
  final String parserName; // SBIParser, HDFCParser, UniversalExcelParser
  final String parserVersion; // 2.0.1
  final int confidenceScore; // 96
  final DateTime importTimestamp;
  final String? hash;

  TransactionProvenance({
    required this.origin,
    required this.parserName,
    required this.parserVersion,
    required this.confidenceScore,
    DateTime? importTimestamp,
    this.hash,
  }) : importTimestamp = importTimestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'parserName': parserName,
        'parserVersion': parserVersion,
        'confidenceScore': confidenceScore,
        'importTimestamp': importTimestamp.toIso8601String(),
        'hash': hash,
      };
}
