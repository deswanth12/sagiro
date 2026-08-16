class ImportSession {
  final String id;
  final DateTime createdDate;
  final String source; // PDF, Excel, CSV, OCR
  final String parserName;
  final String parserVersion;
  final Duration duration;
  final int importedCount;
  final int duplicateCount;
  final Map<String, int>
      skipExplanations; // { 'Duplicate': 3, 'Invalid Date': 1 }
  final int healthScore;

  ImportSession({
    required this.id,
    DateTime? createdDate,
    required this.source,
    required this.parserName,
    required this.parserVersion,
    required this.duration,
    required this.importedCount,
    required this.duplicateCount,
    required this.skipExplanations,
    required this.healthScore,
  }) : createdDate = createdDate ?? DateTime.now();
}
