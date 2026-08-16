import '../models/transaction.dart';

enum TransactionConfidenceLevel { high, needsReview, low }

class TransactionConfidenceResult {
  final TransactionConfidenceLevel level;
  final String reason;

  const TransactionConfidenceResult({
    required this.level,
    required this.reason,
  });

  String get badgeText {
    switch (level) {
      case TransactionConfidenceLevel.high:
        return '🟢 High Confidence';
      case TransactionConfidenceLevel.needsReview:
        return '🟡 Needs Review';
      case TransactionConfidenceLevel.low:
        return '🔴 Low Confidence';
    }
  }
}

class TransactionConfidenceService {
  static TransactionConfidenceResult evaluate(TransactionItem item) {
    // 🔴 Low confidence rules
    if (item.amount <= 0) {
      return const TransactionConfidenceResult(
        level: TransactionConfidenceLevel.low,
        reason: 'Invalid transaction amount (<= ₹0).',
      );
    }

    final merchantClean = item.merchant.trim().toLowerCase();

    // 🟡 Needs review rules
    if (merchantClean.isEmpty || merchantClean == 'unknown' || merchantClean == 'bank' || merchantClean.length < 3) {
      return const TransactionConfidenceResult(
        level: TransactionConfidenceLevel.needsReview,
        reason: 'Merchant name could not be confidently identified.',
      );
    }

    if (item.date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return const TransactionConfidenceResult(
        level: TransactionConfidenceLevel.needsReview,
        reason: 'Transaction date is set in the future.',
      );
    }

    if (item.amount > 100000) {
      return const TransactionConfidenceResult(
        level: TransactionConfidenceLevel.needsReview,
        reason: 'High-value transaction requires explicit confirmation.',
      );
    }

    // 🟢 High confidence default
    return const TransactionConfidenceResult(
      level: TransactionConfidenceLevel.high,
      reason: 'Valid amount, date, transaction type, and verified merchant info.',
    );
  }
}
