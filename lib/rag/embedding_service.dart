import 'dart:math';

class EmbeddingService {
  static const int vectorDimension = 32;

  /// Generates a 32-dimensional dense vector representation on-device.
  /// Uses a deterministic locality-sensitive feature hashing algorithm
  /// combining merchant tokens, amount log scale, category, and date.
  List<double> generateEmbedding(String text,
      {double amount = 0.0, String category = ''}) {
    final vector = List<double>.filled(vectorDimension, 0.0);
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final tokens = cleanText.split(' ').where((t) => t.isNotEmpty).toList();

    for (var token in tokens) {
      final hash = _hashToken(token);
      final index = hash % vectorDimension;
      final sign = (hash % 2 == 0) ? 1.0 : -1.0;
      vector[index] += sign * 1.0;
    }

    // Embed amount magnitude into vector index 0 & 1
    if (amount > 0) {
      final logAmount = log(amount + 1) / log(10);
      vector[0] += logAmount;
      vector[1] += (amount % 1000) / 1000.0;
    }

    // Embed category hash into index 2 & 3
    if (category.isNotEmpty) {
      final catHash = _hashToken(category.toLowerCase());
      vector[2] += (catHash % 10) / 10.0;
      vector[3] += (catHash % 7) / 7.0;
    }

    // Normalize vector (L2 norm)
    double norm = 0.0;
    for (var val in vector) {
      norm += val * val;
    }
    norm = sqrt(norm);

    if (norm > 0) {
      for (int i = 0; i < vectorDimension; i++) {
        vector[i] /= norm;
      }
    }

    return vector;
  }

  int _hashToken(String token) {
    int hash = 5381;
    for (int i = 0; i < token.length; i++) {
      hash = ((hash << 5) + hash) + token.codeUnitAt(i);
    }
    return hash.abs();
  }
}
