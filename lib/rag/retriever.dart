import '../models/transaction.dart';
import '../models/subscription.dart';
import 'embedding_service.dart';
import 'financial_documents.dart';
import 'vector_store.dart';

class HybridRetriever {
  final VectorStore _vectorStore = VectorStore();
  final EmbeddingService _embeddingService = EmbeddingService();

  void indexFinancialData({
    required List<TransactionItem> transactions,
    required List<SubscriptionItem> subscriptions,
  }) {
    _vectorStore.clear();

    // 1. Index Transactions
    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      final text =
          "${t.merchant} ${t.category} ₹${t.amount.toInt()} ${t.type.name} ${t.notes ?? ''}";
      final vector = _embeddingService.generateEmbedding(text,
          amount: t.amount, category: t.category);

      _vectorStore.addDocument(
        FinancialDocument(
          id: t.id != null
              ? 'tx_${t.id}'
              : 'tx_${t.date.millisecondsSinceEpoch}_$i',
          type: DocumentType.transaction,
          content: text,
          embedding: vector,
          transaction: t,
          metadata: {
            'merchant': t.merchant,
            'category': t.category,
            'amount': t.amount,
            'date': t.date,
            'type': t.type.name,
          },
        ),
      );
    }

    // 2. Index Subscriptions
    for (int i = 0; i < subscriptions.length; i++) {
      final s = subscriptions[i];
      final text =
          "Subscription ${s.merchant} ₹${s.averageAmount.toInt()}/mo ${s.category}";
      final vector = _embeddingService.generateEmbedding(text,
          amount: s.averageAmount, category: s.category);

      _vectorStore.addDocument(
        FinancialDocument(
          id: 'sub_${s.merchant}_$i',
          type: DocumentType.subscription,
          content: text,
          embedding: vector,
          subscription: s,
          metadata: {
            'merchant': s.merchant,
            'category': s.category,
            'amount': s.averageAmount,
          },
        ),
      );
    }
  }

  List<FinancialDocument> retrieveContext(String query, {int topK = 8}) {
    final queryVector = _embeddingService.generateEmbedding(query);
    final searchResults = _vectorStore.search(queryVector, topK: topK);
    return searchResults.map((r) => r.document).toList();
  }
}
