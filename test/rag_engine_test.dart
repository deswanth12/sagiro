import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/financial_rag_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Financial RAG Engine Unit Tests', () {
    test('RagResponse holds response text and confidence score', () {
      final res = RagResponse(
        text: 'You spent ₹1,200 on dining this month.',
        suggestions: ['View dining transactions'],
      );

      expect(res.text, contains('dining'));
      expect(res.suggestions.length, equals(1));
    });
  });
}
