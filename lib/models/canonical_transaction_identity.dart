import 'transaction.dart';

/// DuplicateConfidenceLevel — 3-tiered confidence hierarchy for transaction deduplication.
enum DuplicateConfidenceLevel {
  /// Strong bank / UPI reference match within same profile/account. Auto-merge safe.
  exactDuplicate,

  /// Matching profile, account, amount, type, date, and normalized merchant. Auto-merge safe.
  highConfidenceMatch,

  /// Contextual similarity without strong proof. Requires user review (Keep both / Merge / Cancel).
  possibleDuplicate,

  /// Independent financial event. Must NOT be merged or deduplicated.
  distinct,
}

class DuplicateEvaluation {
  final DuplicateConfidenceLevel confidence;
  final String reason;
  final TransactionItem? matchedExisting;

  const DuplicateEvaluation({
    required this.confidence,
    required this.reason,
    this.matchedExisting,
  });

  bool get isDuplicate =>
      confidence == DuplicateConfidenceLevel.exactDuplicate ||
      confidence == DuplicateConfidenceLevel.highConfidenceMatch;

  bool get needsUserReview =>
      confidence == DuplicateConfidenceLevel.possibleDuplicate;
}

/// CanonicalTransactionIdentity — Deterministic Financial Event Signature Engine.
///
/// Guarantees: ONE REAL-WORLD FINANCIAL EVENT = EXACTLY ONE CANONICAL FINGERPRINT.
///
/// Hierarchy:
/// 1. Strong Bank / UPI Reference ID (UTR / RRN / IMPS / NEFT / UPI Ref / Cheque)
/// 2. Contextual Composite (Profile + Account + Date YYYY-MM-DD + Time Bucket + Amount + Type + Normalized Merchant)
class CanonicalTransactionIdentity {
  static final RegExp _cleanRefRegex = RegExp(r'[^a-zA-Z0-9]');
  static final RegExp _noiseWordsRegex = RegExp(
    r'\b(?:pvt\s+ltd|private\s+limited|ltd|store|payment|payments|pay|via\s+upi|upi\s+txn|towards|paid\s+to|transfer\s+to|vpa|pos|e-commerce|services|service|india|corp|corporation|systems|system|solutions|technologies|enterprises|enterprise|retail)\b',
    caseSensitive: false,
  );

  /// Computes a deterministic canonical fingerprint for any [TransactionItem].
  static String computeFingerprint(TransactionItem tx) {
    final profileId =
        tx.profileId.trim().isEmpty ? 'default_profile' : tx.profileId.trim();
    final normAmount = tx.amount.toStringAsFixed(2);
    final typeStr = tx.type.name.toLowerCase();
    final accountSig = normalizeAccountForFingerprint(tx.account);

    // ── 1. Strong Bank Reference ID ──────────────────────────────────────────
    final ref = extractAndNormalizeReference(tx);
    if (ref != null && ref.length >= 4 && !_isGenericRef(ref)) {
      return 'REF|$profileId|$accountSig|$ref|$normAmount|$typeStr';
    }

    // ── 2. Contextual Composite ──────────────────────────────────────────────
    final dateStr =
        '${tx.date.year.toString().padLeft(4, '0')}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';

    String timeBucket;
    if (tx.date.hour != 0 || tx.date.minute != 0) {
      final bucketMin = (tx.date.minute ~/ 10) * 10;
      timeBucket =
          '${tx.date.hour.toString().padLeft(2, '0')}:${bucketMin.toString().padLeft(2, '0')}';
    } else {
      timeBucket = 'ALLDAY';
    }

    final normMerchant = normalizeMerchantForFingerprint(tx.merchant);

    return 'COMP|$profileId|$accountSig|$dateStr|$timeBucket|$normAmount|$typeStr|$normMerchant';
  }

  /// Normalizes reference values across SMS, statements, UPI, and bank formats.
  /// Understands: UPI/123456/Pay, REF: RRN-987654, UTR:123456789, TXN-00123, IMPS/P2A/123456
  static String? normalizeReference(String? rawRef) {
    if (rawRef == null) return null;
    var ref = rawRef.trim().toLowerCase();
    if (ref.isEmpty || _isGenericRef(ref)) return null;

    // 1. Strip common prefix keywords and separators repeatedly
    final prefixRegex = RegExp(
      r'^(?:upi|ref|rrn|utr|txn|txn_id|txnid|imps|neft|chq|cheque|reference)[\s:/\-_#]+',
      caseSensitive: false,
    );
    while (prefixRegex.hasMatch(ref)) {
      ref = ref.replaceAll(prefixRegex, '').trim();
    }

    // 2. Handle structured path format like UPI/123456789/Pay or IMPS/P2A/123456789012
    if (ref.contains('/')) {
      final parts = ref.split('/');
      for (final part in parts) {
        final cleanPart = part.replaceAll(_cleanRefRegex, '');
        // Bank UTRs / RRNs are typically 6-22 digits
        if (cleanPart.length >= 6 && RegExp(r'^\d+$').hasMatch(cleanPart)) {
          return cleanPart;
        }
      }
      // If no pure digit part, check for longest alphanumeric part >= 6 chars
      for (final part in parts) {
        final cleanPart = part.replaceAll(_cleanRefRegex, '');
        if (cleanPart.length >= 6 && !_isGenericRef(cleanPart)) {
          return cleanPart;
        }
      }
    }

    // 3. Strip all non-alphanumeric characters
    final clean = ref.replaceAll(_cleanRefRegex, '');
    if (clean.length >= 4 && !_isGenericRef(clean)) {
      return clean;
    }

    return null;
  }

  /// Extracts and normalizes reference number from a [TransactionItem] (from transactionReference or notes).
  static String? extractAndNormalizeReference(TransactionItem tx) {
    if (tx.transactionReference != null &&
        tx.transactionReference!.trim().isNotEmpty) {
      final norm = normalizeReference(tx.transactionReference);
      if (norm != null) return norm;
    }

    if (tx.notes != null && tx.notes!.isNotEmpty) {
      final match = RegExp(
        r'(?:ref|rrn|utr|upi\s*ref|txn\s*id|reference)[\s:#\-_/]+([a-zA-Z0-9\-_/]{4,35})',
        caseSensitive: false,
      ).firstMatch(tx.notes!);
      if (match != null && match.group(1) != null) {
        final norm = normalizeReference(match.group(1));
        if (norm != null) return norm;
      }
    }

    return null;
  }

  /// Normalizes account identifier into a standardized `bank_last4` token.
  static String normalizeAccountForFingerprint(String? rawAccount) {
    if (rawAccount == null || rawAccount.trim().isEmpty) {
      return 'any_acc';
    }
    final text = rawAccount.trim().toLowerCase();

    // Extract last 4 digits
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : (digits.isNotEmpty ? digits : 'xxxx');

    // Extract bank name standard key
    String bankKey = 'bank';
    if (text.contains('hdfc')) {
      bankKey = 'hdfc';
    } else if (text.contains('sbi') || text.contains('state bank')) {
      bankKey = 'sbi';
    } else if (text.contains('icici')) {
      bankKey = 'icici';
    } else if (text.contains('axis')) {
      bankKey = 'axis';
    } else if (text.contains('kotak')) {
      bankKey = 'kotak';
    } else if (text.contains('pnb') || text.contains('punjab')) {
      bankKey = 'pnb';
    } else if (text.contains('bob') || text.contains('baroda')) {
      bankKey = 'bob';
    } else if (text.contains('canara')) {
      bankKey = 'canara';
    } else if (text.contains('idfc')) {
      bankKey = 'idfc';
    } else if (text.contains('paytm')) {
      bankKey = 'paytm';
    } else if (text.contains('amazon')) {
      bankKey = 'amazon';
    } else if (text.contains('cred')) {
      bankKey = 'cred';
    }

    return '${bankKey}_$last4';
  }

  /// Normalizes merchant names to prevent harmless punctuation/suffix differences from creating duplicates.
  static String normalizeMerchantForFingerprint(String rawMerchant) {
    var m = rawMerchant.toLowerCase().trim();
    // Strip raw SMS sender prefixes like "VM-HDFCBK" if accidentally passed as merchant
    m = m.replaceAll(
        RegExp(r'^(?:vm|vk|ad|bz|bw|ix|ax|jd|bp|cp|ip|qp)-[a-z0-9]+\s*',
            caseSensitive: false),
        '');
    m = m.replaceAll(_noiseWordsRegex, ' ');
    m = m.replaceAll(RegExp(r'[\._\-–—,/#*()\[\]{}@&!?:;]'), ' ');
    m = m.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (m.isEmpty) return 'unknown';
    return m;
  }

  /// Evaluates duplicate status between a candidate transaction and existing records.
  static DuplicateEvaluation evaluateDuplicateAgainstList({
    required TransactionItem candidate,
    required List<TransactionItem> existingList,
  }) {
    // Strict profile isolation: filter to matching profile
    final sameProfileList =
        existingList.where((e) => e.profileId == candidate.profileId).toList();

    // 1. Exact Reference Match Check (Highest Priority)
    final candRef = extractAndNormalizeReference(candidate);
    if (candRef != null && candRef.length >= 4) {
      for (final existing in sameProfileList) {
        final exRef = extractAndNormalizeReference(existing);
        if (exRef != null && exRef == candRef) {
          // Compatible transaction type & amount within ₹0.05
          if (candidate.type == existing.type &&
              (candidate.amount - existing.amount).abs() < 0.05) {
            return DuplicateEvaluation(
              confidence: DuplicateConfidenceLevel.exactDuplicate,
              reason:
                  'Exact match on bank reference ($candRef) & amount (₹${candidate.amount.toStringAsFixed(2)})',
              matchedExisting: existing,
            );
          }
        }
      }
    }

    // 2. High-Confidence Match (Same Profile + Account + Date + Amount + Type + High Merchant Similarity)
    final candNormMerchant =
        normalizeMerchantForFingerprint(candidate.merchant);
    final candNormAccount = normalizeAccountForFingerprint(candidate.account);

    for (final existing in sameProfileList) {
      // Must match type and exact amount
      if (candidate.type != existing.type) continue;
      if ((candidate.amount - existing.amount).abs() >= 0.05) continue;

      // If both records carry explicit reference IDs and they differ, they are distinct transactions
      final exRef = extractAndNormalizeReference(existing);
      if (candRef != null && exRef != null && candRef != exRef) {
        continue;
      }

      // Dates must be on the same calendar day (or max 1-day variance for settlement vs authorization)
      final daysDiff = candidate.date.difference(existing.date).inDays.abs();
      final isSameDay = candidate.date.year == existing.date.year &&
          candidate.date.month == existing.date.month &&
          candidate.date.day == existing.date.day;

      if (!isSameDay && daysDiff > 1) continue;

      // Check merchant similarity
      final exNormMerchant = normalizeMerchantForFingerprint(existing.merchant);
      final merchantSimilarity =
          _calculateMerchantSimilarity(candNormMerchant, exNormMerchant);

      // Check account compatibility
      final exNormAccount = normalizeAccountForFingerprint(existing.account);
      final accountsCompatible = candNormAccount == 'any_acc' ||
          exNormAccount == 'any_acc' ||
          candNormAccount == exNormAccount;

      // Check timestamps if both have non-zero time
      final candHasTime =
          candidate.date.hour != 0 || candidate.date.minute != 0;
      final exHasTime = existing.date.hour != 0 || existing.date.minute != 0;

      if (isSameDay && accountsCompatible) {
        if (candHasTime && exHasTime) {
          final timeDiffMin =
              candidate.date.difference(existing.date).inMinutes.abs();
          // If transactions occurred > 30 mins apart on same day at same merchant -> LEGITIMATE SEPARATE TXN!
          if (timeDiffMin > 30) {
            continue;
          }
        }

        if (merchantSimilarity >= 0.85) {
          return DuplicateEvaluation(
            confidence: DuplicateConfidenceLevel.highConfidenceMatch,
            reason:
                'High-confidence match on date, amount, account, and merchant ($candNormMerchant)',
            matchedExisting: existing,
          );
        } else if (merchantSimilarity >= 0.50 ||
            (candNormMerchant == 'unknown' || exNormMerchant == 'unknown')) {
          return DuplicateEvaluation(
            confidence: DuplicateConfidenceLevel.possibleDuplicate,
            reason:
                'Possible duplicate on same date & amount (₹${candidate.amount.toStringAsFixed(2)}) with similar merchant',
            matchedExisting: existing,
          );
        }
      }
    }

    return const DuplicateEvaluation(
      confidence: DuplicateConfidenceLevel.distinct,
      reason: 'Unique financial event',
    );
  }

  static double _calculateMerchantSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a.contains(b) || b.contains(a)) return 0.90;

    final tokensListA = a.split(' ').where((s) => s.isNotEmpty).toList();
    final tokensListB = b.split(' ').where((s) => s.isNotEmpty).toList();
    if (tokensListA.isEmpty || tokensListB.isEmpty) return 0.0;

    // Brand root prefix matching (e.g. "uber" in "uber auto" and "uber india")
    if (tokensListA.first == tokensListB.first &&
        tokensListA.first.length >= 3) {
      return 0.88;
    }

    // Token set overlap (Jaccard similarity)
    final tokensA = tokensListA.toSet();
    final tokensB = tokensListB.toSet();

    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    return intersection / union;
  }

  static bool _isGenericRef(String ref) {
    final lower = ref.toLowerCase().trim();
    return lower.isEmpty ||
        lower == 'null' ||
        lower == 'none' ||
        lower == 'na' ||
        lower == 'xxxx' ||
        lower == 'nil' ||
        lower == '0' ||
        RegExp(r'^0+$').hasMatch(lower);
  }
}
