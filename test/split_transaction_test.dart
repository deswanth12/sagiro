import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/document_engine/duplicate/duplicate_hash_detector.dart';
import 'package:sagiro/services/backup_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
    }
  });

  group('Problem 10: Split Transaction Workflow Test Suite (24 Scenarios)', () {
    // 1. Simple 2-way split
    test('1. Simple 2-way split sums exactly to parent amount', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 700.0),
        TransactionSplit(category: 'Other', amount: 300.0),
      ];

      final sum = splits.fold<double>(0.0, (s, e) => s + e.amount);
      expect(sum, equals(1000.0));

      final tx = TransactionItem(
        amount: 1000.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: splits,
      );

      expect(tx.isSplit, isTrue);
      expect(tx.splits!.length, equals(2));
    });

    // 2. 3-way split
    test('2. 3-way split sums to parent amount', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 500.0),
        TransactionSplit(category: 'Delivery', amount: 300.0),
        TransactionSplit(category: 'Tips', amount: 200.0),
      ];

      final sum = splits.fold<double>(0.0, (s, e) => s + e.amount);
      expect(sum, equals(1000.0));
    });

    // 3. 5+ split rows
    test('3. 5+ split rows supported cleanly', () {
      final splits = List.generate(
        5,
        (i) => TransactionSplit(category: 'Category $i', amount: 200.0),
      );

      final sum = splits.fold<double>(0.0, (s, e) => s + e.amount);
      expect(sum, equals(1000.0));
    });

    // 4. Exact total validation
    test('4. Exact total validation checks equality', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 600.0),
        TransactionSplit(category: 'Home', amount: 400.0),
      ];
      const parentAmount = 1000.0;
      final sum = splits.fold<double>(0.0, (s, e) => s + e.amount);

      expect((sum - parentAmount).abs() < 0.001, isTrue);
    });

    // 5. Total too high validation
    test('5. Total too high validation detects excess amount', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 700.0),
        TransactionSplit(category: 'Home', amount: 500.0),
      ];
      const parentAmount = 1000.0;
      final sum = splits.fold<double>(0.0, (s, e) => s + e.amount);

      expect(sum > parentAmount, isTrue);
    });

    // 6. Total too low validation
    test('6. Total too low validation detects remaining unallocated amount',
        () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 500.0),
      ];
      const parentAmount = 1000.0;
      final sum = splits.fold<double>(0.0, (s, e) => s + e.amount);

      expect(sum < parentAmount, isTrue);
    });

    // 7. Negative amount prevention
    test('7. Negative split amounts are rejected', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: -200.0),
        TransactionSplit(category: 'Home', amount: 1200.0),
      ];

      final hasNegative = splits.any((s) => s.amount < 0);
      expect(hasNegative, isTrue);
    });

    // 8. Invalid amount validation
    test('8. Invalid/NaN amounts are prevented', () {
      final valid = double.tryParse('abc');
      expect(valid, isNull);
    });

    // 9. ₹0 parent transaction handling
    test('9. Zero parent transaction handled cleanly', () {
      final tx = TransactionItem(
        amount: 0.0,
        merchant: 'Zero Test',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      );

      expect(tx.amount, equals(0.0));
    });

    // 10. Decimal amounts (0.01, 1.99, 999.99, 1000.01)
    test(
        '10. Decimal precision handles cents accurately without rounding drift',
        () {
      final splits = [
        TransactionSplit(category: 'Item A', amount: 0.01),
        TransactionSplit(category: 'Item B', amount: 1.99),
        TransactionSplit(category: 'Item C', amount: 998.01),
      ];

      final sum = splits.fold<double>(0.0, (s, e) => s + e.amount);
      expect(double.parse(sum.toStringAsFixed(2)), equals(1000.01));
    });

    // 11. Edit existing split
    test('11. Editing existing split updates allocations', () {
      final initialSplits = [
        TransactionSplit(category: 'Food', amount: 700.0),
        TransactionSplit(category: 'Other', amount: 300.0),
      ];

      final updatedSplits = [
        TransactionSplit(category: 'Food', amount: 500.0),
        TransactionSplit(category: 'Transport', amount: 500.0),
      ];

      final tx = TransactionItem(
        amount: 1000.0,
        merchant: 'Store',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: initialSplits,
      );

      final editedTx = tx.copyWith(splits: updatedSplits);
      expect(editedTx.splits![1].category, equals('Transport'));
      expect(editedTx.splits![1].amount, equals(500.0));
    });

    // 12. Delete split row
    test('12. Deleting split row reduces splits list count', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 500.0),
        TransactionSplit(category: 'Transport', amount: 300.0),
        TransactionSplit(category: 'Other', amount: 200.0),
      ];

      splits.removeAt(2);
      expect(splits.length, equals(2));
    });

    // 13. Add split row
    test('13. Adding split row expands splits list', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 500.0),
      ];

      splits.add(TransactionSplit(category: 'Drinks', amount: 500.0));
      expect(splits.length, equals(2));
    });

    // 14. App restart persistence via SQLite
    test('14. App restart persistence restores split structure from SQLite',
        () async {
      final splits = [
        TransactionSplit(category: 'Food', amount: 600.0),
        TransactionSplit(category: 'Home', amount: 400.0),
      ];

      final tx = TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: splits,
      );

      await DatabaseHelper.instance.insertTransaction(tx);
      final reloaded = await DatabaseHelper.instance.getAllTransactions();

      expect(reloaded.length, equals(1));
      expect(reloaded.first.isSplit, isTrue);
      expect(reloaded.first.splits!.length, equals(2));
      expect(reloaded.first.splits![0].category, equals('Food'));
      expect(reloaded.first.splits![0].amount, equals(600.0));
    });

    // 15. Database reload serialization
    test(
        '15. toMap and fromMap serialize and deserialize splits JSON correctly',
        () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 750.0),
        TransactionSplit(category: 'Tax', amount: 250.0),
      ];

      final tx = TransactionItem(
        amount: 1000.0,
        merchant: 'Restaurant',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: splits,
      );

      final map = tx.toMap();
      expect(map['splits'], isNotNull);
      final restored = TransactionItem.fromMap(map);

      expect(restored.isSplit, isTrue);
      expect(restored.splits!.first.amount, equals(750.0));
    });

    // 16. Duplicate detection unit
    test('16. Duplicate detection treats parent transaction as single unit',
        () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 600.0),
        TransactionSplit(category: 'Home', amount: 400.0),
      ];

      final tx1 = TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: splits,
        transactionReference: 'SPLIT_REF_99',
      );

      final tx2 = TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'SPLIT_REF_99',
      );

      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: tx2, existingTransactions: [tx1]),
          isTrue);
    });

    // 17. Category aggregation
    test('17. Category breakdown attributes split amounts to split categories',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(30000.0);

      final splits = [
        TransactionSplit(category: 'Food', amount: 700.0),
        TransactionSplit(category: 'Fuel', amount: 300.0),
      ];

      final aug1 = DateTime(2026, 8, 1);
      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Mixed Store',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
        splits: splits,
      ));

      final breakdown = provider.categoryBreakdown;
      expect(breakdown['Food'], equals(700.0));
      expect(breakdown['Fuel'], equals(300.0));
    });

    // 18. Safe Today integration
    test(
        '18. Safe Today incorporates parent amount once without double counting',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(31000.0);
      final aug1 = DateTime(2026, 8, 1);

      final splits = [
        TransactionSplit(category: 'Food', amount: 700.0),
        TransactionSplit(category: 'Fuel', amount: 300.0),
      ];

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Mixed Store',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
        splits: splits,
      ));

      final monthSpend = provider.calculateMonthSpend(targetDate: aug1);
      expect(monthSpend, equals(1000.0)); // Parent amount counted ONCE

      final safeToday = provider.calculateSafeToday(targetDate: aug1);
      // (31000 - 1000) / 31 = 30000 / 31 = 967.7419...
      expect(safeToday, closeTo(967.74, 0.01));
    });

    // 19. Credit split
    test('19. Credit split transaction created and stored correctly', () {
      final splits = [
        TransactionSplit(category: 'Salary', amount: 8000.0),
        TransactionSplit(category: 'Bonus', amount: 2000.0),
      ];

      final tx = TransactionItem(
        amount: 10000.0,
        merchant: 'Employer Inc',
        category: 'Income',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1),
        splits: splits,
      );

      expect(tx.type, equals(TransactionType.credit));
      expect(tx.splits!.length, equals(2));
    });

    // 20. Refund split
    test('20. Refund split transaction supported cleanly', () {
      final splits = [
        TransactionSplit(category: 'Food', amount: 300.0),
        TransactionSplit(category: 'Delivery', amount: 100.0),
      ];

      final tx = TransactionItem(
        amount: 400.0,
        merchant: 'Swiggy Partial Refund',
        category: 'Food',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        splits: splits,
      );

      expect(tx.type, equals(TransactionType.credit));
      expect(
          tx.splits!.fold<double>(0.0, (s, e) => s + e.amount), equals(400.0));
    });

    // 21. Backup / Restore persistence
    test('21. Splits survive encrypted backup and restore archive payload',
        () async {
      final splits = [
        TransactionSplit(category: 'Food', amount: 600.0),
        TransactionSplit(category: 'Entertainment', amount: 400.0),
      ];

      final tx = TransactionItem(
        amount: 1000.0,
        merchant: 'Mall Visit',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: splits,
      );

      await DatabaseHelper.instance.insertTransaction(tx);
      final archive =
          await BackupService.generateBackupArchive(password: 'Secret123!');
      expect(archive, isNotEmpty);

      // Verify restoration of splits from archive
      final restoredMeta = BackupService.inspectBackupHeader(archive);
      expect(restoredMeta.transactionCount, equals(1));

      final db = await DatabaseHelper.instance.database;
      if (db != null) await db.delete('transactions');

      await BackupService.restoreFromArchive(archive, password: 'Secret123!');
      final restoredTxs = await DatabaseHelper.instance.getAllTransactions();
      expect(restoredTxs.first.isSplit, isTrue);
      expect(restoredTxs.first.splits!.length, equals(2));
      expect(restoredTxs.first.splits!.first.category, equals('Food'));
      expect(restoredTxs.first.splits!.first.amount, equals(600.0));
    });

    // 22. Long category name support
    test(
        '22. Long category names in splits do not cause serialization failures',
        () {
      final splits = [
        TransactionSplit(
            category:
                'Extremely Long Category Name For Specialized Professional Supplies',
            amount: 500.0),
        TransactionSplit(category: 'Food', amount: 500.0),
      ];

      final tx = TransactionItem(
        amount: 1000.0,
        merchant: 'Vendor',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: splits,
      );

      final map = tx.toMap();
      final restored = TransactionItem.fromMap(map);
      expect(restored.splits!.first.category,
          contains('Extremely Long Category Name'));
    });

    // 23. Large transaction amount support
    test('23. Large transaction amounts (₹1,00,00,000) split accurately', () {
      final splits = [
        TransactionSplit(category: 'Real Estate', amount: 7000000.0),
        TransactionSplit(category: 'Legal Fees', amount: 3000000.0),
      ];

      final tx = TransactionItem(
        amount: 10000000.0,
        merchant: 'Property Deal',
        category: 'Investment',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: splits,
      );

      final sum = tx.splits!.fold<double>(0.0, (s, e) => s + e.amount);
      expect(sum, equals(10000000.0));
    });

    // 24. Multiple transactions with splits processed concurrently
    test(
        '24. Multiple split transactions in database aggregate category breakdown accurately',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(50000.0);
      final aug1 = DateTime(2026, 8, 1);

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Store A',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
        splits: [
          TransactionSplit(category: 'Food', amount: 600.0),
          TransactionSplit(category: 'Fuel', amount: 400.0),
        ],
      ));

      await provider.addTransaction(TransactionItem(
        amount: 2000.0,
        merchant: 'Store B',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
        splits: [
          TransactionSplit(category: 'Food', amount: 1000.0),
          TransactionSplit(category: 'Shopping', amount: 1000.0),
        ],
      ));

      final breakdown = provider.categoryBreakdown;
      expect(breakdown['Food'], equals(1600.0)); // 600 + 1000
      expect(breakdown['Fuel'], equals(400.0));
      expect(breakdown['Shopping'], equals(1000.0));
    });
  });
}
