import 'transaction.dart';

/// TransactionDraft — Staging data structure for incoming transactions from any source.
/// Holds raw parsed data prior to canonical normalization, deduplication, and database commitment.
class TransactionDraft {
  final double amount;
  final String merchant;
  final String category;
  final TransactionType type;
  final TransactionSource source;
  final DateTime date;
  final String? account;
  final String? notes;
  final String? transactionReference;
  final String? rawSms;
  final List<TransactionSplit>? splits;
  final String profileId;
  final bool isShared;
  final String? sourceMessageId;
  final List<String>? sourceTypes;

  TransactionDraft({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.type,
    required this.source,
    required this.date,
    this.account,
    this.notes,
    this.transactionReference,
    this.rawSms,
    this.splits,
    this.profileId = 'default_profile',
    this.isShared = false,
    this.sourceMessageId,
    this.sourceTypes,
  });

  /// Converts this draft to a full [TransactionItem].
  TransactionItem toTransactionItem({int? id, String? transactionFingerprint}) {
    return TransactionItem(
      id: id,
      amount: amount,
      merchant: merchant,
      category: category,
      type: type,
      source: source,
      date: date,
      account: account,
      notes: notes,
      transactionReference: transactionReference,
      rawSms: rawSms,
      splits: splits,
      profileId: profileId,
      isShared: isShared,
      sourceMessageId: sourceMessageId,
      sourceTypes: sourceTypes ?? [source.name],
      transactionFingerprint: transactionFingerprint,
    );
  }

  factory TransactionDraft.fromTransactionItem(TransactionItem item) {
    return TransactionDraft(
      amount: item.amount,
      merchant: item.merchant,
      category: item.category,
      type: item.type,
      source: item.source,
      date: item.date,
      account: item.account,
      notes: item.notes,
      transactionReference: item.transactionReference,
      rawSms: item.rawSms,
      splits: item.splits,
      profileId: item.profileId,
      isShared: item.isShared,
      sourceMessageId: item.sourceMessageId,
      sourceTypes: item.sourceTypes,
    );
  }

  TransactionDraft copyWith({
    double? amount,
    String? merchant,
    String? category,
    TransactionType? type,
    TransactionSource? source,
    DateTime? date,
    String? account,
    String? notes,
    String? transactionReference,
    String? rawSms,
    List<TransactionSplit>? splits,
    String? profileId,
    bool? isShared,
    String? sourceMessageId,
    List<String>? sourceTypes,
  }) {
    return TransactionDraft(
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      type: type ?? this.type,
      source: source ?? this.source,
      date: date ?? this.date,
      account: account ?? this.account,
      notes: notes ?? this.notes,
      transactionReference: transactionReference ?? this.transactionReference,
      rawSms: rawSms ?? this.rawSms,
      splits: splits ?? this.splits,
      profileId: profileId ?? this.profileId,
      isShared: isShared ?? this.isShared,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      sourceTypes: sourceTypes ?? this.sourceTypes,
    );
  }
}
