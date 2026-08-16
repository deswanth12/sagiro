import '../models/spending_request_model.dart';
import '../../../models/transaction.dart';

class FamilyMemoryRecord {
  final String id;
  final String familyId;
  final String actorName;
  final String actionDescription;
  final DateTime timestamp;

  const FamilyMemoryRecord({
    required this.id,
    required this.familyId,
    required this.actorName,
    required this.actionDescription,
    required this.timestamp,
  });
}

class FamilyMemoryEngine {
  /// Searches actual family financial memory and transaction history.
  /// If no matching real records exist, returns an honest empty state response.
  static String queryMemory(
    String query, {
    List<TransactionItem> transactions = const [],
    List<SpendingRequest> requests = const [],
  }) {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) {
      return 'No family financial memory is available yet.';
    }

    // 1. Search actual spending requests
    final matchingRequests = requests
        .where((r) =>
            r.title.toLowerCase().contains(q) ||
            r.reason.toLowerCase().contains(q) ||
            r.requesterName.toLowerCase().contains(q))
        .toList();

    if (matchingRequests.isNotEmpty) {
      final req = matchingRequests.first;
      final statusStr = req.status == SpendingRequestStatus.approved
          ? 'approved'
          : req.status == SpendingRequestStatus.declined
              ? 'declined'
              : 'requested';
      return '${req.requesterName} $statusStr ₹${req.amount.toStringAsFixed(0)} for ${req.title}.';
    }

    // 2. Search actual transactions
    final matchingTx = transactions
        .where((t) =>
            t.merchant.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            (t.notes != null && t.notes!.toLowerCase().contains(q)))
        .toList();

    if (matchingTx.isNotEmpty) {
      final tx = matchingTx.first;
      return 'Logged ₹${tx.amount.toStringAsFixed(0)} for ${tx.merchant} under ${tx.category}.';
    }

    return 'No family financial memory is available yet.';
  }
}
