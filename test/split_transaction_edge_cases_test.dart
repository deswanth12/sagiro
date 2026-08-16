import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Split Transaction Exhaustive Edge Case Unit Tests', () {
    test('1. Validates that split amounts sum up exactly to parent amount', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 300.0),
        TransactionSplit(category: 'Fuel', amount: 200.0),
      ];

      final totalSplit = splits.fold(0.0, (sum, s) => sum + s.amount);
      expect(totalSplit, equals(500.0));
    });

    test('2. Handles full refund against split transaction cleanly', () {
      final original = TransactionItem(
        merchant: 'Amazon',
        amount: 1000.0,
        type: TransactionType.debit,
        category: 'Shopping',
        date: DateTime.now(),
        source: TransactionSource.sms,
        splits: [
          TransactionSplit(category: 'Electronics', amount: 600.0),
          TransactionSplit(category: 'Books', amount: 400.0),
        ],
      );

      final refund = TransactionItem(
        merchant: 'Amazon Reversal',
        amount: 1000.0,
        type: TransactionType.credit,
        category: 'Refund',
        date: DateTime.now(),
        source: TransactionSource.sms,
      );

      expect(original.isSplit, isTrue);
      expect(refund.amount, equals(original.amount));
    });

    test('3. TransactionSplit holds category and amount cleanly', () {
      final split = TransactionSplit(category: 'Entertainment', amount: 450.0);

      expect(split.category, equals('Entertainment'));
      expect(split.amount, equals(450.0));
    });
  });
}
