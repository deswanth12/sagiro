import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../models/transaction.dart';
import '../../models/canonical_transaction_identity.dart';

class DuplicateHashDetector {
  /// Computes a unique signature hash for a transaction using CanonicalTransactionIdentity.
  static String computeHash(TransactionItem tx) {
    final fp = CanonicalTransactionIdentity.computeFingerprint(tx);
    return sha256.convert(utf8.encode(fp)).toString();
  }

  /// Evaluates duplicate status using the 3-tier canonical confidence engine.
  static bool isDuplicate({
    required TransactionItem candidate,
    required List<TransactionItem> existingTransactions,
    List<TransactionItem> currentBatch = const [],
  }) {
    // 1. Evaluate against existing database records
    final dbEval = CanonicalTransactionIdentity.evaluateDuplicateAgainstList(
      candidate: candidate,
      existingList: existingTransactions,
    );
    if (dbEval.isDuplicate) return true;

    // 2. Evaluate against preceding items in current batch
    if (currentBatch.isNotEmpty) {
      final batchEval =
          CanonicalTransactionIdentity.evaluateDuplicateAgainstList(
        candidate: candidate,
        existingList: currentBatch,
      );
      if (batchEval.isDuplicate) return true;
    }

    return false;
  }

  static DuplicateEvaluation evaluateDuplicate({
    required TransactionItem candidate,
    required List<TransactionItem> existingTransactions,
  }) {
    return CanonicalTransactionIdentity.evaluateDuplicateAgainstList(
      candidate: candidate,
      existingList: existingTransactions,
    );
  }
}
