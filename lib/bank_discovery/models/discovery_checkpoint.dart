class DiscoveryCheckpoint {
  final int? lastProcessedSmsId;
  final DateTime? lastProcessedTimestamp;
  final int totalScannedCount;
  final DateTime? lastScanDate;

  DiscoveryCheckpoint({
    this.lastProcessedSmsId,
    this.lastProcessedTimestamp,
    this.totalScannedCount = 0,
    this.lastScanDate,
  });

  DiscoveryCheckpoint copyWith({
    int? lastProcessedSmsId,
    DateTime? lastProcessedTimestamp,
    int? totalScannedCount,
    DateTime? lastScanDate,
  }) {
    return DiscoveryCheckpoint(
      lastProcessedSmsId: lastProcessedSmsId ?? this.lastProcessedSmsId,
      lastProcessedTimestamp:
          lastProcessedTimestamp ?? this.lastProcessedTimestamp,
      totalScannedCount: totalScannedCount ?? this.totalScannedCount,
      lastScanDate: lastScanDate ?? this.lastScanDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastProcessedSmsId': lastProcessedSmsId,
      'lastProcessedTimestamp': lastProcessedTimestamp?.toIso8601String(),
      'totalScannedCount': totalScannedCount,
      'lastScanDate': lastScanDate?.toIso8601String(),
    };
  }

  factory DiscoveryCheckpoint.fromMap(Map<String, dynamic> map) {
    return DiscoveryCheckpoint(
      lastProcessedSmsId: map['lastProcessedSmsId'] as int?,
      lastProcessedTimestamp:
          DateTime.tryParse(map['lastProcessedTimestamp'] as String? ?? ''),
      totalScannedCount: map['totalScannedCount'] as int? ?? 0,
      lastScanDate: DateTime.tryParse(map['lastScanDate'] as String? ?? ''),
    );
  }
}
