import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/database_helper.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Database Restore Rollback & Failure Tests', () {
    test(
        'Native SQLite restore failure rethrows error and preserves existing database state',
        () async {
      final db = DatabaseHelper.instance;
      await db.clearAllData();

      // Insert an existing transaction
      final initialTx = TransactionItem(
        amount: 1000.0,
        merchant: 'Existing Merchant',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
      );
      await db.insertTransaction(initialTx);

      final beforeTxs = await db.getAllTransactions();
      expect(beforeTxs.length, equals(1));

      // Malformed transaction map that causes SQLite type constraint error
      final invalidRawTransactions = [
        {
          'amount': 'INVALID_DOUBLE_STRING',
          'merchant': null,
          'category': 12345,
          'type': 'debit',
          'source': 'manual',
          'date': 'invalid_date'
        }
      ];

      expect(
        () => db.restoreFullDatabaseTransaction(
          rawTransactions: invalidRawTransactions,
          rawRules: [],
          rawSettings: {},
        ),
        throwsA(anything),
      );

      // Verify database state is untouched (rolled back)
      final afterTxs = await db.getAllTransactions();
      expect(afterTxs.length, equals(1));
      expect(afterTxs.first.merchant, equals('Existing Merchant'));
    });
  });
}
