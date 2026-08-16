import '../models/transaction.dart';
import '../models/subscription.dart';

enum DocumentType {
  transaction,
  merchant,
  budget,
  savingsGoal,
  bill,
  subscription,
  monthlySummary,
  timelineEvent,
  achievement
}

class FinancialDocument {
  final String id;
  final DocumentType type;
  final String content;
  final List<double> embedding;
  final TransactionItem? transaction;
  final SubscriptionItem? subscription;
  final Map<String, dynamic> metadata;

  FinancialDocument({
    required this.id,
    required this.type,
    required this.content,
    required this.embedding,
    this.transaction,
    this.subscription,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'metadata': metadata,
    };
  }
}
