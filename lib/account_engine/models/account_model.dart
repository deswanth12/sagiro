import 'account_type.dart';

class AccountModel {
  final String id;
  final String bankName;
  final AccountCategory accountType;
  final String nickname;
  final String maskedAccountNumber;
  final String? ifsc;
  final double? openingBalance;
  final double estimatedBalance;
  final double lastKnownBalance;
  final String currency;
  final String colorHex;
  final String iconEmoji;
  final bool isPrimary;
  final bool isArchived;
  final DateTime? lastTransactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.nickname,
    required this.maskedAccountNumber,
    this.ifsc,
    this.openingBalance,
    required this.estimatedBalance,
    required this.lastKnownBalance,
    this.currency = 'INR',
    this.colorHex = '#0EA5E9',
    required this.iconEmoji,
    this.isPrimary = false,
    this.isArchived = false,
    this.lastTransactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'accountType': accountType.name,
      'nickname': nickname,
      'maskedAccountNumber': maskedAccountNumber,
      'ifsc': ifsc,
      'openingBalance': openingBalance,
      'estimatedBalance': estimatedBalance,
      'lastKnownBalance': lastKnownBalance,
      'currency': currency,
      'colorHex': colorHex,
      'iconEmoji': iconEmoji,
      'isPrimary': isPrimary ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'lastTransactionDate': lastTransactionDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      bankName: map['bankName'] as String,
      accountType: AccountCategory.values.firstWhere(
        (e) => e.name == map['accountType'],
        orElse: () => AccountCategory.savings,
      ),
      nickname: map['nickname'] as String,
      maskedAccountNumber: map['maskedAccountNumber'] as String,
      ifsc: map['ifsc'] as String?,
      openingBalance: (map['openingBalance'] as num?)?.toDouble(),
      estimatedBalance: (map['estimatedBalance'] as num).toDouble(),
      lastKnownBalance: (map['lastKnownBalance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'INR',
      colorHex: map['colorHex'] as String? ?? '#0EA5E9',
      iconEmoji: map['iconEmoji'] as String? ?? '🏦',
      isPrimary: (map['isPrimary'] as int?) == 1,
      isArchived: (map['isArchived'] as int?) == 1,
      lastTransactionDate: map['lastTransactionDate'] != null
          ? DateTime.tryParse(map['lastTransactionDate'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  AccountModel copyWith({
    String? nickname,
    double? estimatedBalance,
    double? lastKnownBalance,
    bool? isPrimary,
    bool? isArchived,
    DateTime? lastTransactionDate,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id,
      bankName: bankName,
      accountType: accountType,
      nickname: nickname ?? this.nickname,
      maskedAccountNumber: maskedAccountNumber,
      ifsc: ifsc,
      openingBalance: openingBalance,
      estimatedBalance: estimatedBalance ?? this.estimatedBalance,
      lastKnownBalance: lastKnownBalance ?? this.lastKnownBalance,
      currency: currency,
      colorHex: colorHex,
      iconEmoji: iconEmoji,
      isPrimary: isPrimary ?? this.isPrimary,
      isArchived: isArchived ?? this.isArchived,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
