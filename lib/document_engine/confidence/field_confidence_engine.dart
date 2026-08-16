import '../models/field_confidence.dart';
import '../../models/transaction.dart';

class FieldConfidenceEngine {
  static FieldConfidence evaluate({
    required TransactionItem transaction,
    required bool isRecognizedTemplate,
    required bool isBalanceVerified,
    required bool isNormalizedMerchant,
  }) {
    int dateScore = 100;
    int amountScore = transaction.amount > 0 ? 100 : 0;
    int merchantScore = isNormalizedMerchant ? 95 : 85;
    int balanceScore = isBalanceVerified ? 100 : 80;
    int refScore =
        (transaction.notes != null && transaction.notes!.isNotEmpty) ? 90 : 75;

    final reasons = <String>[];
    if (isRecognizedTemplate) reasons.add('Recognized Bank Template');
    if (transaction.amount > 0) reasons.add('Amount Verified');
    if (isNormalizedMerchant) reasons.add('Merchant Normalized');
    if (isBalanceVerified) reasons.add('Balance Verified');

    final overall =
        ((dateScore + amountScore + merchantScore + balanceScore + refScore) /
                5.0)
            .round();

    return FieldConfidence(
      dateConfidence: dateScore,
      amountConfidence: amountScore,
      merchantConfidence: merchantScore,
      balanceConfidence: balanceScore,
      referenceConfidence: refScore,
      overallConfidence: overall.clamp(0, 100),
      reasons: reasons,
    );
  }
}
