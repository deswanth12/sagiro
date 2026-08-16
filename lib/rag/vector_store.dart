import 'dart:math';
import 'financial_documents.dart';

class VectorSearchResult {
  final FinancialDocument document;
  final double similarityScore;

  VectorSearchResult({required this.document, required this.similarityScore});
}

class VectorStore {
  // Map-based storage for O(1) upsert (was O(n) List removeWhere + add).
  final Map<String, FinancialDocument> _documents = {};

  /// Upsert a document by its unique ID (O(1)).
  void addDocument(FinancialDocument doc) {
    _documents[doc.id] = doc;
  }

  /// Bulk upsert (O(n) where n = docs.length, not O(n²)).
  void addDocuments(List<FinancialDocument> docs) {
    for (var doc in docs) {
      _documents[doc.id] = doc;
    }
  }

  void clear() {
    _documents.clear();
  }

  int get count => _documents.length;

  /// Cosine Similarity Vector Search
  List<VectorSearchResult> search(List<double> queryVector,
      {int topK = 10, double minSimilarity = 0.1}) {
    if (_documents.isEmpty) return [];

    final results = <VectorSearchResult>[];

    for (var doc in _documents.values) {
      final similarity = _calculateCosineSimilarity(queryVector, doc.embedding);
      if (similarity >= minSimilarity) {
        results.add(
            VectorSearchResult(document: doc, similarityScore: similarity));
      }
    }

    results.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return results.take(topK).toList();
  }

  double _calculateCosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return (dotProduct / (sqrt(normA) * sqrt(normB))).clamp(0.0, 1.0);
  }
}
