import '../../models/transaction.dart';
import '../../document_engine/duplicate/duplicate_hash_detector.dart';

class ValidationRuleResult {
  final bool isValid;
  final String? skipReason; // e.g. Duplicate, Invalid Date, Missing Amount

  const ValidationRuleResult({required this.isValid, this.skipReason});
}

class ValidationEngine {
  static ValidationRuleResult validateTransaction({
    required TransactionItem tx,
    required List<TransactionItem> existingTransactions,
  }) {
    if (tx.amount <= 0) {
      return const ValidationRuleResult(
          isValid: false, skipReason: 'Missing or Zero Amount');
    }

    if (tx.date.year < 2000 || tx.date.year > 2100) {
      return const ValidationRuleResult(
          isValid: false, skipReason: 'Invalid Date Format');
    }

    final isDuplicate = DuplicateHashDetector.isDuplicate(
      candidate: tx,
      existingTransactions: existingTransactions,
    );

    if (isDuplicate) {
      return const ValidationRuleResult(
          isValid: false, skipReason: 'Duplicate Transaction');
    }

    return const ValidationRuleResult(isValid: true);
  }
}
