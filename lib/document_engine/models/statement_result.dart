import '../../models/transaction.dart';
import 'field_confidence.dart';
import 'statement_health.dart';

class StatementResultItem {
  final TransactionItem transaction;
  final FieldConfidence confidence;
  final bool isDuplicate;
  final bool isUserCorrected;

  StatementResultItem({
    required this.transaction,
    required this.confidence,
    this.isDuplicate = false,
    this.isUserCorrected = false,
  });
}

class StatementResult {
  final List<StatementResultItem> items;
  final StatementHealth health;
  final bool isPasswordProtected;
  final bool isDecryptedSuccessfully;
  final String? errorMessage;
  final List<String> warnings;

  StatementResult({
    required this.items,
    required this.health,
    this.isPasswordProtected = false,
    this.isDecryptedSuccessfully = true,
    this.errorMessage,
    this.warnings = const [],
  });

  bool get requiresPassword => isPasswordProtected && !isDecryptedSuccessfully;

  int get readyCount =>
      items.where((i) => !i.isDuplicate && !i.confidence.needsReview).length;
  int get duplicateCount => items.where((i) => i.isDuplicate).length;
  int get reviewCount =>
      items.where((i) => i.confidence.needsReview && !i.isDuplicate).length;
}
