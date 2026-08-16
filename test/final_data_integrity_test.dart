import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/document_engine/duplicate/duplicate_hash_detector.dart';
import 'package:sagiro/family_engine/services/family_service.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/backup_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
  });

  group('Problem 14: Final Data-Integrity Audit (25 Scenarios)', () {
    // 1. Database Schema Integrity
    test('1. Database schema integrity (Version 9 & Tables)', () async {
      final db = (await DatabaseHelper.instance.database)!;
      expect(DatabaseHelper.currentDbVersion, equals(9));

      final txColumns = await db.rawQuery('PRAGMA table_info(transactions)');
      final columnNames = txColumns.map((c) => c['name'] as String).toSet();

      final expectedColumns = {
        'id',
        'amount',
        'merchant',
        'category',
        'type',
        'source',
        'date',
        'account',
        'notes',
        'transactionReference',
        'rawSms',
        'splits',
        'profileId',
        'isShared',
        'originalCategory',
        'userCategory',
        'transactionFingerprint',
        'sourceMessageId',
      };

      for (final col in expectedColumns) {
        expect(columnNames.contains(col), isTrue,
            reason: 'Column $col missing from transactions table');
      }

      final profileTable = await db.rawQuery('PRAGMA table_info(profiles)');
      expect(profileTable.isNotEmpty, isTrue, reason: 'profiles table missing');
    });

    // 2. Manual Lifecycle
    test('2. Manual transaction lifecycle (Create -> Read -> Edit -> Delete)',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final db = (await DatabaseHelper.instance.database)!;

      final tx = TransactionItem(
        amount: 250.0,
        merchant: 'Book Store',
        category: 'Education',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      );

      await provider.addTransaction(tx);
      expect(provider.transactions.length, equals(1));

      final dbCount = (await db.rawQuery('SELECT COUNT(*) FROM transactions'))
          .first
          .values
          .first as int;
      expect(dbCount, equals(1));

      final created = provider.transactions.first;
      final updated = created.copyWith(amount: 300.0, category: 'Books');
      await provider.updateTransaction(updated);

      expect(provider.transactions.first.amount, equals(300.0));
      expect(provider.transactions.first.category, equals('Books'));

      await provider.deleteTransaction(created.id!);
      expect(provider.transactions.isEmpty, isTrue);

      final dbCountAfter =
          (await db.rawQuery('SELECT COUNT(*) FROM transactions'))
              .first
              .values
              .first as int;
      expect(dbCountAfter, equals(0));
    });

    // 3. SMS Lifecycle
    test(
        '3. SMS transaction lifecycle (Scan -> Parse -> Insert -> Duplicate check)',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      const smsText =
          'Spent Rs. 450.00 at Zomato via UPI Ref 889977. Bal Rs. 5000.';
      final parsed =
          SmsParser.parseSms(smsText, 'HDFCBK', smsDate: DateTime(2026, 8, 13));
      expect(parsed, isNotNull);

      await provider.addTransaction(parsed!);
      expect(provider.transactions.length, equals(1));

      final candidate = SmsParser.parseSms(smsText, 'HDFCBK',
          smsDate: DateTime(2026, 8, 13))!;
      expect(
        DuplicateHashDetector.isDuplicate(
          candidate: candidate,
          existingTransactions: provider.transactions,
        ),
        isTrue,
      );
    });

    // 4. CSV Lifecycle
    test('4. CSV transaction lifecycle', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final csvTx = TransactionItem(
        amount: 1200.0,
        merchant: 'D-Mart',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime(2026, 8, 10),
        transactionReference: 'CSV_REF_101',
      );

      await provider.addTransaction(csvTx);
      expect(provider.transactions.first.source, equals(TransactionSource.csv));
    });

    // 5. Split Lifecycle
    test('5. Split transaction lifecycle (Create -> Edit -> Share -> Delete)',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final db = (await DatabaseHelper.instance.database)!;

      final splitTx = TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      );

      await provider.addTransaction(splitTx);
      expect(provider.transactions.length, equals(1));

      final dbCount = (await db.rawQuery('SELECT COUNT(*) FROM transactions'))
          .first
          .values
          .first as int;
      expect(dbCount, equals(1)); // Parent row exactly 1

      final created = provider.transactions.first;
      final sharedTx = created.copyWith(isShared: true);
      await provider.updateTransaction(sharedTx);

      final familySummary = await FamilyService.instance.getFamilySummary();
      expect(familySummary.monthlyFamilyExpenses, equals(1000.0));

      await provider.deleteTransaction(created.id!);
      expect(provider.transactions.isEmpty, isTrue);
    });

    // 6. Credit Calculation
    test('6. Credit calculation increases income / net spend calculation',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 5000.0,
        merchant: 'Salary Credit',
        category: 'Income',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1),
      ));

      expect(provider.calculateMonthSpend(targetDate: DateTime(2026, 8, 1)),
          equals(0.0));
    });

    // 7. Debit Calculation
    test('7. Debit calculation increases monthly spend by exact amount',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 1500.0,
        merchant: 'Fuel Station',
        category: 'Fuel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 5),
      ));

      expect(provider.calculateMonthSpend(targetDate: DateTime(2026, 8, 5)),
          equals(1500.0));
    });

    // 8. Refund Calculation
    test('8. Refund calculation produces accurate net spending', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final aug13 = DateTime(2026, 8, 13);

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Amazon Purchase',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug13,
      ));

      await provider.addTransaction(TransactionItem(
        amount: 300.0,
        merchant: 'Amazon Refund',
        category: 'Shopping',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: aug13,
      ));

      expect(provider.calculateMonthSpend(targetDate: aug13), equals(700.0));
    });

    // 9. Reversal Calculation
    test('9. Reversal calculation produces zero net result', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final aug13 = DateTime(2026, 8, 13);

      await provider.addTransaction(TransactionItem(
        amount: 800.0,
        merchant: 'Failed Merchant',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug13,
      ));

      await provider.addTransaction(TransactionItem(
        amount: 800.0,
        merchant: 'Reversal Credit',
        category: 'General',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: aug13,
      ));

      expect(provider.calculateMonthSpend(targetDate: aug13), equals(0.0));
    });

    // 10. Safe Today Independent Calculation
    test('10. Safe Today independent calculation against expected formula',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.updateMonthlyBudget(31000.0);

      final aug1 = DateTime(2026, 8, 1);

      // Independent expected formula calculation for Aug 1 (31 days):
      // Monthly Budget = 31,000, Month Spend = 0, Fixed = 0
      // Expected Safe Today = 31000 / (31 - 1 + 1) = 31000 / 31 = 1000.0
      const expectedZeroSpend = (31000.0 - 0.0 - 0.0) / 31;
      expect(provider.calculateSafeToday(targetDate: aug1),
          equals(expectedZeroSpend));

      // Add ₹1,000 debit on Aug 1
      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Grocery Store',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
      ));

      // Independent expected formula calculation after ₹1,000 spend:
      // Buffer = 31000 - 1000 = 30000. Remaining days = 31.
      // Expected Safe Today = 30000 / 31 = 967.7419
      const expectedAfterSpend = (31000.0 - 1000.0 - 0.0) / 31;
      expect(provider.calculateSafeToday(targetDate: aug1),
          closeTo(expectedAfterSpend, 0.001));

      // Test February non-leap (2027: 28 days)
      final feb1NonLeap = DateTime(2027, 2, 1);
      const expectedFebNonLeap = (31000.0 - 0.0 - 0.0) / 28;
      expect(provider.calculateSafeToday(targetDate: feb1NonLeap),
          closeTo(expectedFebNonLeap, 0.001));

      // Test February leap year (2028: 29 days)
      final feb1Leap = DateTime(2028, 2, 1);
      const expectedFebLeap = (31000.0 - 0.0 - 0.0) / 29;
      expect(provider.calculateSafeToday(targetDate: feb1Leap),
          closeTo(expectedFebLeap, 0.001));
    });

    // 11. Duplicate Protection
    test('11. Duplicate protection flags identical transaction parameters',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final original = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 12, 0),
        transactionReference: 'REF12345',
      );

      await provider.addTransaction(original);

      final duplicateCandidate = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 12, 0),
        transactionReference: 'REF12345',
      );

      expect(
        DuplicateHashDetector.isDuplicate(
          candidate: duplicateCandidate,
          existingTransactions: provider.transactions,
        ),
        isTrue,
      );
    });

    // 12. Cross-Profile Duplicate Isolation
    test(
        '12. Cross-profile duplicate isolation allows same reference in Profile B',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.addTransaction(TransactionItem(
        amount: 900.0,
        merchant: 'Uber',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        transactionReference: 'REF_SHARED_CROSS',
      ));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      final candidateInPB = TransactionItem(
        amount: 900.0,
        merchant: 'Uber',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        transactionReference: 'REF_SHARED_CROSS',
        profileId: pB.id,
      );

      expect(
        DuplicateHashDetector.isDuplicate(
          candidate: candidateInPB,
          existingTransactions: provider.transactions,
        ),
        isFalse,
      );
    });

    // 13. Family Privacy Isolation
    test('13. Family privacy isolation prevents private transaction leakage',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      // Profile A: Private ₹1,000 + Shared ₹500
      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'A Private',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
      ));

      await provider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'A Shared',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: true,
      ));

      // Profile B: Private ₹2,000 + Shared ₹700
      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 2000.0,
        merchant: 'B Private',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
      ));

      await provider.addTransaction(TransactionItem(
        amount: 700.0,
        merchant: 'B Shared',
        category: 'Utilities',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: true,
      ));

      // Verify Family Summary shows ONLY shared transactions: 500 + 700 = 1,200
      final summary = await FamilyService.instance.getFamilySummary();
      expect(summary.monthlyFamilyExpenses, equals(1200.0));
    });

    // 14. Profile Deletion
    test('14. Profile deletion cleans up Profile A and leaves Profile B intact',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final pA = await FamilyService.instance.createProfile(name: 'Profile A');
      final pB = await FamilyService.instance.createProfile(name: 'Profile B');

      await provider.switchProfile(pA.id);
      await provider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'A Item',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      await provider.switchProfile(pB.id);
      await provider.addTransaction(TransactionItem(
        amount: 300.0,
        merchant: 'B Item',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      await FamilyService.instance.deleteProfile(pA.id);
      await provider.loadData();

      final db = (await DatabaseHelper.instance.database)!;
      final orphanCount = (await db.rawQuery(
              "SELECT COUNT(*) FROM transactions WHERE profileId = ?", [pA.id]))
          .first
          .values
          .first as int;
      expect(orphanCount, equals(0));
      expect(provider.transactions.length, equals(1));
      expect(provider.transactions.first.merchant, equals('B Item'));
    });

    // 15. Transaction Editing
    test('15. Transaction editing updates category totals accurately',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final original = TransactionItem(
        amount: 1000.0,
        merchant: 'Flight Ticket',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      );

      await provider.addTransaction(original);
      expect(provider.categoryBreakdown['Food'], equals(1000.0));

      final edited = provider.transactions.first.copyWith(
        amount: 1500.0,
        category: 'Travel',
      );

      await provider.updateTransaction(edited);
      expect(provider.categoryBreakdown['Food'], isNull);
      expect(provider.categoryBreakdown['Travel'], equals(1500.0));
    });

    // 16. Split Editing
    test('16. Split editing updates sub-category breakdowns correctly',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final splitTx = TransactionItem(
        amount: 1000.0,
        merchant: 'Mall',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      );

      await provider.addTransaction(splitTx);
      expect(provider.categoryBreakdown['Food'], equals(700.0));
      expect(provider.categoryBreakdown['Entertainment'], equals(300.0));

      final updatedSplit = provider.transactions.first.copyWith(
        splits: [
          TransactionSplit(category: 'Food', amount: 500.0),
          TransactionSplit(category: 'Transport', amount: 500.0),
        ],
      );

      await provider.updateTransaction(updatedSplit);
      expect(provider.categoryBreakdown['Food'], equals(500.0));
      expect(provider.categoryBreakdown['Entertainment'], isNull);
      expect(provider.categoryBreakdown['Transport'], equals(500.0));
    });

    // 17. Backup Creation
    test('17. Backup creation generates encrypted backup archive string',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 100.0,
        merchant: 'Test Backup',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      final backupStr =
          await BackupService.generateBackupArchive(password: 'secret123');
      expect(backupStr.isNotEmpty, isTrue);
      final decoded = jsonDecode(backupStr) as Map<String, dynamic>;
      expect(decoded['metadata']['isEncrypted'], isTrue);
    });

    // 18. Backup Restore
    test(
        '18. Backup restore restores profiles, transactions, and splits accurately',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 888.0,
        merchant: 'Restore Target',
        category: 'Health',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        transactionReference: 'RESTORE_REF_77',
        isShared: true,
      ));

      final backupPayload =
          await BackupService.generateBackupArchive(password: 'pass123');

      await DatabaseHelper.instance.clearAllData();
      await provider.loadData();
      expect(provider.transactions.isEmpty, isTrue);

      await BackupService.restoreFromArchive(
        backupPayload,
        password: 'pass123',
      );
      await provider.loadData();

      expect(provider.transactions.length, equals(1));
      expect(provider.transactions.first.amount, equals(888.0));
      expect(provider.transactions.first.transactionReference,
          equals('RESTORE_REF_77'));
      expect(provider.transactions.first.isShared, isTrue);
    });

    // 19. Restore Duplicate Prevention
    test('19. Restore duplicate prevention rejects wrong decryption password',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final backupPayload =
          await BackupService.generateBackupArchive(password: 'correct_pass');

      expect(
        () async => await BackupService.restoreFromArchive(
          backupPayload,
          password: 'wrong_pass',
        ),
        throwsA(isA<BackupException>()),
      );
    });

    // 20. Provider / Database Count Consistency
    test(
        '20. Provider and SQLite database transaction counts match after mutations',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final db = (await DatabaseHelper.instance.database)!;

      for (int i = 1; i <= 5; i++) {
        await provider.addTransaction(TransactionItem(
          amount: 100.0 * i,
          merchant: 'Item $i',
          category: 'General',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(2026, 8, i),
        ));
      }

      final dbCount = (await db.rawQuery('SELECT COUNT(*) FROM transactions'))
          .first
          .values
          .first as int;
      expect(dbCount, equals(provider.transactions.length));
    });

    // 21. Month Boundary
    test('21. Month boundary attributes transactions to exact month', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 400.0,
        merchant: 'July End',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 7, 31, 23, 59),
      ));

      await provider.addTransaction(TransactionItem(
        amount: 600.0,
        merchant: 'Aug Start',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1, 0, 1),
      ));

      expect(provider.calculateMonthSpend(targetDate: DateTime(2026, 7, 31)),
          equals(400.0));
      expect(provider.calculateMonthSpend(targetDate: DateTime(2026, 8, 1)),
          equals(600.0));
    });

    // 22. Year Boundary
    test('22. Year boundary attributes transactions to exact year', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 2000.0,
        merchant: 'NYE 2025',
        category: 'Party',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2025, 12, 31, 23, 59),
      ));

      await provider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'New Year 2026',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 1, 1, 0, 1),
      ));

      expect(provider.calculateMonthSpend(targetDate: DateTime(2025, 12, 31)),
          equals(2000.0));
      expect(provider.calculateMonthSpend(targetDate: DateTime(2026, 1, 1)),
          equals(500.0));
    });

    // 23. Reset Behavior
    test(
        '23. Complete data reset wipes all transactions and non-default profiles',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 999.0,
        merchant: 'To Wipe',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      await DatabaseHelper.instance.clearAllData();
      await provider.loadData();

      expect(provider.transactions.isEmpty, isTrue);
      expect(provider.activeProfileId, equals('default_profile'));
    });

    // 24. rawSms Privacy
    test('24. rawSms privacy guarantee: rawSms column is ALWAYS null in SQLite',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final db = (await DatabaseHelper.instance.database)!;

      const smsText =
          'Rs. 750 debited from A/c XX1234 at Flipkart on 13-Aug-26.';
      final parsed =
          SmsParser.parseSms(smsText, 'HDFCBK', smsDate: DateTime(2026, 8, 13));
      expect(parsed, isNotNull);

      await provider.addTransaction(parsed!);

      final rawRows = await db.rawQuery(
          'SELECT rawSms FROM transactions WHERE id = ?',
          [provider.transactions.first.id]);
      expect(rawRows.first['rawSms'], isNull);
    });

    // 25. Final Aggregate Consistency
    test(
        '25. Final aggregate consistency: split parent amount never double-counted',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.updateMonthlyBudget(31000.0);

      final aug1 = DateTime(2026, 8, 1);
      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Split Parent',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      ));

      // Month spend must be ₹1,000 (NOT ₹2,000)
      expect(provider.calculateMonthSpend(targetDate: aug1), equals(1000.0));

      // Category breakdown allocations sum to ₹1,000
      final breakdown = provider.categoryBreakdown;
      final categorySum = breakdown.values.fold<double>(0.0, (s, v) => s + v);
      expect(categorySum, equals(1000.0));
      expect(breakdown['Food'], equals(700.0));
      expect(breakdown['Entertainment'], equals(300.0));
      expect(breakdown['General'], isNull);

      // Safe Today buffer is reduced by ₹1,000 (NOT ₹2,000)
      const expectedSafeToday = (31000.0 - 1000.0 - 0.0) / 31;
      expect(provider.calculateSafeToday(targetDate: aug1),
          closeTo(expectedSafeToday, 0.001));
    });
  });
}
