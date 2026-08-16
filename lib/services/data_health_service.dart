import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/transaction.dart';

enum DataHealthStatus { excellent, good, needsReview, attentionRequired }

class DataHealthReport {
  final DataHealthStatus status;
  final int totalTransactions;
  final int incomeCount;
  final int expenseCount;
  final int unresolvedDuplicatesCount;
  final int transactionsRequiringReviewCount;
  final int failedImportsCount;
  final DateTime? lastSmsScan;
  final DateTime? lastStatementImport;
  final DateTime? lastBackup;

  const DataHealthReport({
    required this.status,
    required this.totalTransactions,
    required this.incomeCount,
    required this.expenseCount,
    required this.unresolvedDuplicatesCount,
    required this.transactionsRequiringReviewCount,
    required this.failedImportsCount,
    this.lastSmsScan,
    this.lastStatementImport,
    this.lastBackup,
  });

  String get statusBadgeText {
    switch (status) {
      case DataHealthStatus.excellent:
        return '🟢 Excellent';
      case DataHealthStatus.good:
        return '🟢 Good';
      case DataHealthStatus.needsReview:
        return '🟡 Needs Review';
      case DataHealthStatus.attentionRequired:
        return '🔴 Attention Required';
    }
  }
}

class DataHealthService {
  static String computeTxHash(TransactionItem tx) {
    final raw = '${tx.date.year}_${tx.date.month}_${tx.date.day}_${tx.amount.toStringAsFixed(2)}_${tx.merchant.trim().toLowerCase()}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static DataHealthReport evaluate(List<TransactionItem> transactions, {
    int failedImportsCount = 0,
    DateTime? lastSmsScan,
    DateTime? lastStatementImport,
    DateTime? lastBackup,
  }) {
    int income = 0;
    int expense = 0;
    int reviewNeeded = 0;

    final Set<String> hashes = {};
    int duplicatesCount = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.credit) {
        income++;
      } else {
        expense++;
      }

      // Check review criteria
      final isMerchantUncertain = tx.merchant.trim().isEmpty || tx.merchant.toLowerCase().contains('unknown');
      final isAmountUncertain = tx.amount <= 0;
      if (isMerchantUncertain || isAmountUncertain) {
        reviewNeeded++;
      }

      // Hash duplicate check
      final hash = computeTxHash(tx);
      if (hashes.contains(hash)) {
        duplicatesCount++;
      } else {
        hashes.add(hash);
      }
    }

    DataHealthStatus status;
    if (failedImportsCount > 0) {
      status = DataHealthStatus.attentionRequired;
    } else if (duplicatesCount > 0 || reviewNeeded > 2) {
      status = DataHealthStatus.needsReview;
    } else if (reviewNeeded > 0) {
      status = DataHealthStatus.good;
    } else {
      status = DataHealthStatus.excellent;
    }

    return DataHealthReport(
      status: status,
      totalTransactions: transactions.length,
      incomeCount: income,
      expenseCount: expense,
      unresolvedDuplicatesCount: duplicatesCount,
      transactionsRequiringReviewCount: reviewNeeded,
      failedImportsCount: failedImportsCount,
      lastSmsScan: lastSmsScan,
      lastStatementImport: lastStatementImport,
      lastBackup: lastBackup,
    );
  }
}
