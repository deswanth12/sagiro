import '../models/transaction.dart';
import '../models/subscription.dart';

class FinancialDocument {
  final String id;
  final String text;
  final TransactionItem? transaction;
  final SubscriptionItem? subscription;
  final Map<String, dynamic> metadata;

  FinancialDocument({
    required this.id,
    required this.text,
    this.transaction,
    this.subscription,
    required this.metadata,
  });
}

class RagIndexer {
  final List<FinancialDocument> _documents = [];

  void indexTransactions(List<TransactionItem> transactions) {
    _documents.clear();
    for (var t in transactions) {
      final docText =
          "${t.merchant} ${t.category} ₹${t.amount.toInt()} ${t.type == TransactionType.debit ? 'Debit' : 'Credit'} ${t.source.name} ${t.notes ?? ''} ${t.date.toIso8601String()}";
      _documents.add(
        FinancialDocument(
          id: t.id?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          text: docText.toLowerCase(),
          transaction: t,
          metadata: {
            'merchant': t.merchant.toLowerCase(),
            'category': t.category.toLowerCase(),
            'amount': t.amount,
            'date': t.date,
            'hour': t.date.hour,
            'month': t.date.month,
            'year': t.date.year,
            'isExpense': t.type == TransactionType.debit,
          },
        ),
      );
    }
  }

  List<FinancialDocument> retrieveTopK(String query, {int topK = 10}) {
    final cleanQuery = query.toLowerCase();
    final terms = cleanQuery.split(' ').where((w) => w.length > 2).toList();

    if (terms.isEmpty) {
      return _documents.take(topK).toList();
    }

    final scoredDocs = _documents.map((doc) {
      double score = 0;
      for (var term in terms) {
        if (doc.metadata['merchant'].toString().contains(term)) score += 5;
        if (doc.metadata['category'].toString().contains(term)) score += 3;
        if (doc.text.contains(term)) score += 1;
      }
      return MapEntry(doc, score);
    }).toList();

    scoredDocs.sort((a, b) => b.value.compareTo(a.value));
    return scoredDocs
        .where((e) => e.value > 0)
        .take(topK)
        .map((e) => e.key)
        .toList();
  }
}
