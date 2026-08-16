enum BankConfidenceLevel { high, medium, low, unknown }

class DiscoveredBank {
  final String bankName;
  final String bankCode;
  final BankConfidenceLevel confidenceLevel;
  final double evidenceScore;
  final int confirmedTransactionCount;
  final int balanceActivityCount;
  final List<String> accountLast4Set;
  final DateTime firstSeenDate;
  final DateTime lastSeenDate;
  final bool isPrimary;
  final bool isSecondary;
  final bool userConfirmed;

  DiscoveredBank({
    required this.bankName,
    required this.bankCode,
    required this.confidenceLevel,
    required this.evidenceScore,
    required this.confirmedTransactionCount,
    required this.balanceActivityCount,
    required this.accountLast4Set,
    required this.firstSeenDate,
    required this.lastSeenDate,
    this.isPrimary = false,
    this.isSecondary = false,
    this.userConfirmed = false,
  });

  DiscoveredBank copyWith({
    String? bankName,
    String? bankCode,
    BankConfidenceLevel? confidenceLevel,
    double? evidenceScore,
    int? confirmedTransactionCount,
    int? balanceActivityCount,
    List<String>? accountLast4Set,
    DateTime? firstSeenDate,
    DateTime? lastSeenDate,
    bool? isPrimary,
    bool? isSecondary,
    bool? userConfirmed,
  }) {
    return DiscoveredBank(
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      evidenceScore: evidenceScore ?? this.evidenceScore,
      confirmedTransactionCount:
          confirmedTransactionCount ?? this.confirmedTransactionCount,
      balanceActivityCount: balanceActivityCount ?? this.balanceActivityCount,
      accountLast4Set: accountLast4Set ?? this.accountLast4Set,
      firstSeenDate: firstSeenDate ?? this.firstSeenDate,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      isPrimary: isPrimary ?? this.isPrimary,
      isSecondary: isSecondary ?? this.isSecondary,
      userConfirmed: userConfirmed ?? this.userConfirmed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'bankCode': bankCode,
      'confidenceLevel': confidenceLevel.name,
      'evidenceScore': evidenceScore,
      'confirmedTransactionCount': confirmedTransactionCount,
      'balanceActivityCount': balanceActivityCount,
      'accountLast4Set': accountLast4Set,
      'firstSeenDate': firstSeenDate.toIso8601String(),
      'lastSeenDate': lastSeenDate.toIso8601String(),
      'isPrimary': isPrimary,
      'isSecondary': isSecondary,
      'userConfirmed': userConfirmed,
    };
  }

  factory DiscoveredBank.fromMap(Map<String, dynamic> map) {
    return DiscoveredBank(
      bankName: map['bankName'] as String? ?? 'Unknown Bank',
      bankCode: map['bankCode'] as String? ?? 'UNKNOWN',
      confidenceLevel: BankConfidenceLevel.values.firstWhere(
        (e) => e.name == map['confidenceLevel'],
        orElse: () => BankConfidenceLevel.unknown,
      ),
      evidenceScore: (map['evidenceScore'] as num? ?? 0.0).toDouble(),
      confirmedTransactionCount: map['confirmedTransactionCount'] as int? ?? 0,
      balanceActivityCount: map['balanceActivityCount'] as int? ?? 0,
      accountLast4Set: (map['accountLast4Set'] as List?)?.cast<String>() ?? [],
      firstSeenDate: DateTime.tryParse(map['firstSeenDate'] as String? ?? '') ??
          DateTime.now(),
      lastSeenDate: DateTime.tryParse(map['lastSeenDate'] as String? ?? '') ??
          DateTime.now(),
      isPrimary: map['isPrimary'] as bool? ?? false,
      isSecondary: map['isSecondary'] as bool? ?? false,
      userConfirmed: map['userConfirmed'] as bool? ?? false,
    );
  }
}
