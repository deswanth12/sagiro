import '../../models/transaction.dart';

class RecordValidationResult {
  final bool isValid;
  final String? errorReason;

  const RecordValidationResult({required this.isValid, this.errorReason});
}

class RecordValidator {
  static RecordValidationResult validate(TransactionItem tx) {
    if (tx.amount <= 0) {
      return const RecordValidationResult(
          isValid: false, errorReason: 'Amount must be greater than 0');
    }

    if (tx.date.year < 2000 || tx.date.year > 2100) {
      return const RecordValidationResult(
          isValid: false, errorReason: 'Date year out of realistic range');
    }

    if (tx.merchant.trim().isEmpty) {
      return const RecordValidationResult(
          isValid: false, errorReason: 'Merchant description is blank');
    }

    return const RecordValidationResult(isValid: true);
  }
}
