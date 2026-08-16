import 'dart:convert';

enum TransactionType { debit, credit }

enum TransactionSource { sms, manual, csv, pdf, excel, ocr, voice, backup }

class TransactionSplit {
  final String category;
  final double amount;

  TransactionSplit({
    required this.category,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
    };
  }

  factory TransactionSplit.fromMap(Map<String, dynamic> map) {
    return TransactionSplit(
      category: map['category'] as String? ?? 'General',
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
    );
  }
}

class TransactionItem {
  final int? id;
  final double amount;
  final String merchant;
  final String _category;
  final TransactionType type;
  final TransactionSource source;
  final DateTime date;
  final String? account;
  final String? notes;

  /// Structured bank reference ID (UTR / RRN / Cheque / UPI Ref).
  /// Preserves duplicate detection while keeping rawSms null.
  final String? transactionReference;

  /// Raw SMS body. Non-null only for SMS-sourced transactions.
  /// Null for manual entries and CSV imports.
  final String? rawSms;

  /// Category split allocations for multi-category transactions.
  final List<TransactionSplit>? splits;

  /// Family profile ownership ID (defaults to 'default_profile')
  final String profileId;

  /// Whether this transaction is explicitly marked shared with the Family Workspace
  final bool isShared;

  final String? originalCategory;
  final String? userCategory;

  /// Deterministic Canonical Fingerprint for Database-Level Unique Deduplication
  final String? transactionFingerprint;

  /// Source Message / Row / Document Identifier (e.g. Android SMS _id)
  final String? sourceMessageId;

  /// Multi-source provenance list (e.g. ['sms', 'pdf'])
  final List<String> sourceTypes;

  TransactionItem({
    this.id,
    required this.amount,
    required this.merchant,
    required String category,
    required this.type,
    required this.source,
    required this.date,
    this.account,
    this.notes,
    String? transactionReference,
    String? reference,
    this.rawSms,
    this.splits,
    this.profileId = 'default_profile',
    this.isShared = false,
    this.originalCategory,
    this.userCategory,
    this.transactionFingerprint,
    this.sourceMessageId,
    List<String>? sourceTypes,
  })  : _category = category,
        transactionReference = transactionReference ?? reference,
        sourceTypes = sourceTypes != null && sourceTypes.isNotEmpty
            ? sourceTypes
            : [source.name];

  /// Effective category priority: userCategory override -> category -> originalCategory -> 'General'
  String get category => userCategory ?? _category;

  /// Structured bank reference alias
  String? get reference => transactionReference;

  bool get isSplit => splits != null && splits!.isNotEmpty;

  /// Human-readable multi-source provenance indicator (e.g. "SMS + PDF" or "SMS")
  String get displaySource {
    if (sourceTypes.isEmpty) return source.name.toUpperCase();
    return sourceTypes.map((s) => s.toUpperCase()).toSet().join(' + ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'category': _category,
      'type': type == TransactionType.debit ? 'debit' : 'credit',
      'source': source.name,
      'date': date.toIso8601String(),
      'account': account,
      'notes': notes,
      'transactionReference': transactionReference,
      'rawSms': null, // P2-01 Privacy: Never persist raw SMS text to database
      'splits': splits != null && splits!.isNotEmpty
          ? jsonEncode(splits!.map((s) => s.toMap()).toList())
          : null,
      'profileId': profileId,
      'isShared': isShared ? 1 : 0,
      'originalCategory': originalCategory ?? _category,
      'userCategory': userCategory,
      'transactionFingerprint': transactionFingerprint,
      'sourceMessageId': sourceMessageId,
      'sourceTypes': jsonEncode(sourceTypes),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    List<TransactionSplit>? parsedSplits;
    if (map['splits'] != null) {
      try {
        final rawSplits = map['splits'];
        final List decoded =
            rawSplits is String ? jsonDecode(rawSplits) : (rawSplits as List);
        parsedSplits = decoded
            .map((s) =>
                TransactionSplit.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList();
      } catch (_) {}
    }

    final rawCategory = map['category'] as String? ?? 'General';
    final userCat = map['userCategory'] as String?;
    final origCat = map['originalCategory'] as String? ?? rawCategory;
    final src = _parseSource(map['source'] as String?);

    List<String> parsedSourceTypes = [];
    if (map['sourceTypes'] != null) {
      try {
        final rawSrc = map['sourceTypes'];
        if (rawSrc is String) {
          if (rawSrc.startsWith('[')) {
            parsedSourceTypes = List<String>.from(jsonDecode(rawSrc) as List);
          } else {
            parsedSourceTypes = rawSrc
                .split(',')
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } else if (rawSrc is List) {
          parsedSourceTypes =
              rawSrc.map((e) => e.toString().toLowerCase()).toList();
        }
      } catch (_) {}
    }
    if (parsedSourceTypes.isEmpty) {
      parsedSourceTypes = [src.name];
    }

    return TransactionItem(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String? ?? 'Unknown Merchant',
      category: rawCategory,
      type: map['type'] == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
      source: src,
      date: (DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now())
          .toLocal(),
      account: map['account'] as String?,
      notes: map['notes'] as String?,
      transactionReference:
          map['transactionReference'] as String? ?? map['reference'] as String?,
      rawSms: map['rawSms'] as String?,
      splits: parsedSplits,
      profileId: map['profileId'] as String? ?? 'default_profile',
      isShared: map['isShared'] == true ||
          map['isShared'] == 1 ||
          map['isShared'] == '1',
      originalCategory: origCat,
      userCategory: userCat,
      transactionFingerprint: map['transactionFingerprint'] as String?,
      sourceMessageId: map['sourceMessageId'] as String?,
      sourceTypes: parsedSourceTypes,
    );
  }

  static TransactionSource _parseSource(String? sourceStr) {
    if (sourceStr == null) return TransactionSource.sms;
    final lower = sourceStr.trim().toLowerCase();
    switch (lower) {
      case 'csv':
        return TransactionSource.csv;
      case 'pdf':
        return TransactionSource.pdf;
      case 'excel':
      case 'xlsx':
      case 'xls':
        return TransactionSource.excel;
      case 'ocr':
      case 'camera':
        return TransactionSource.ocr;
      case 'voice':
        return TransactionSource.voice;
      case 'manual':
        return TransactionSource.manual;
      case 'backup':
        return TransactionSource.backup;
      default:
        return TransactionSource.sms;
    }
  }

  TransactionItem copyWith({
    int? id,
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
    bool clearSplits = false,
    String? profileId,
    bool? isShared,
    String? originalCategory,
    String? userCategory,
    String? transactionFingerprint,
    String? sourceMessageId,
    List<String>? sourceTypes,
  }) {
    final newCategory = category ?? userCategory ?? _category;
    return TransactionItem(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: newCategory,
      type: type ?? this.type,
      source: source ?? this.source,
      date: date ?? this.date,
      account: account ?? this.account,
      notes: notes ?? this.notes,
      transactionReference: transactionReference ?? this.transactionReference,
      rawSms: rawSms ?? this.rawSms,
      splits: clearSplits ? null : (splits ?? this.splits),
      profileId: profileId ?? this.profileId,
      isShared: isShared ?? this.isShared,
      originalCategory: originalCategory ?? this.originalCategory,
      userCategory: userCategory ?? category ?? this.userCategory,
      transactionFingerprint:
          transactionFingerprint ?? this.transactionFingerprint,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      sourceTypes: sourceTypes ?? this.sourceTypes,
    );
  }

  /// Merges this canonical transaction with another representing the same financial event.
  /// Consolidates provenance, retains high-fidelity metadata (reference, exact timestamp, cleaner merchant).
  TransactionItem mergeWith(TransactionItem incoming) {
    final combinedSources = <String>{
      ...sourceTypes,
      ...incoming.sourceTypes,
      incoming.source.name,
    }.toList();

    // Prefer cleaner / more informative merchant name
    String bestMerchant = merchant;
    if (_isCleanerMerchant(incoming.merchant, merchant)) {
      bestMerchant = incoming.merchant;
    }

    // Preserve non-empty bank reference
    String? bestRef = transactionReference;
    if (bestRef == null || bestRef.trim().isEmpty) {
      bestRef = incoming.transactionReference;
    }

    // Preserve exact timestamp (if one has hour/min and other is 00:00)
    DateTime bestDate = date;
    final thisHasTime = date.hour != 0 || date.minute != 0;
    final incomingHasTime =
        incoming.date.hour != 0 || incoming.date.minute != 0;
    if (!thisHasTime && incomingHasTime) {
      bestDate = incoming.date;
    }

    // Preserve non-empty account
    String? bestAccount = account;
    if ((bestAccount == null || bestAccount.trim().isEmpty) &&
        incoming.account != null) {
      bestAccount = incoming.account;
    }

    // Preserve notes
    String? bestNotes = notes;
    if (incoming.notes != null && incoming.notes!.trim().isNotEmpty) {
      if (bestNotes == null || bestNotes.trim().isEmpty) {
        bestNotes = incoming.notes;
      } else if (!bestNotes.contains(incoming.notes!)) {
        bestNotes = '$bestNotes • ${incoming.notes}';
      }
    }

    return copyWith(
      merchant: bestMerchant,
      transactionReference: bestRef,
      date: bestDate,
      account: bestAccount,
      notes: bestNotes,
      sourceTypes: combinedSources,
      userCategory: userCategory ?? incoming.userCategory,
    );
  }

  static bool _isCleanerMerchant(String incoming, String existing) {
    if (existing.trim().isEmpty) return true;
    if (incoming.trim().isEmpty) return false;
    final exLower = existing.toLowerCase();
    final inLower = incoming.toLowerCase();

    // If existing is raw SMS header like "VM-HDFCBK" or generic, and incoming is real name
    if (exLower.startsWith('vm-') ||
        exLower.startsWith('vk-') ||
        exLower.startsWith('ad-')) {
      return true;
    }
    // If incoming is longer and contains existing
    if (incoming.length > existing.length && inLower.contains(exLower)) {
      return true;
    }
    // If incoming has mixed case and existing is all UPPERCASE
    if (existing == existing.toUpperCase() &&
        incoming != incoming.toUpperCase() &&
        incoming.length >= existing.length) {
      return true;
    }
    return false;
  }
}
