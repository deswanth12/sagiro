import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/ask_your_money_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ask Your Money Engine Unit Tests', () {
    test('SpendingAnalyzer parses queries and returns structured answer', () {
      final txs = [
        TransactionItem(
          merchant: 'Swiggy',
          amount: 500.0,
          type: TransactionType.debit,
          category: 'Food',
          date: DateTime.now(),
          source: TransactionSource.sms,
        ),
      ];

      final ans = SpendingAnalyzer.analyze(
        'How much did I spend on food?',
        txs,
        25000.0,
        500.0,
      );

      expect(ans.question.isNotEmpty, isTrue);
      expect(ans.directAnswer.toLowerCase(), contains('food'));
      expect(ans.confidenceScore, greaterThan(0));
    });
  });
}
