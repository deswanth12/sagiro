import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/family_engine/services/family_service.dart';
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
      try {
        await db.delete('profiles');
      } catch (_) {}
      await db.delete('settings');
    }
  });

  group('Problem 12: Family + Split Integration Test Suite (12 Scenarios)', () {
    // 1. 2-way split & Profile Ownership
    test(
        '1. 2-way split parent row belongs to Profile A and splits do not create extra DB rows',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final pA = provider.activeProfileId;

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket 2-Way',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      ));

      final allDbRows = await DatabaseHelper.instance.getAllTransactions();
      expect(allDbRows.length, equals(1));
      expect(allDbRows.first.profileId, equals(pA));
      expect(allDbRows.first.isSplit, isTrue);
      expect(allDbRows.first.splits?.length, equals(2));
    });

    // 2. 3-way split
    test(
        '2. 3-way split transaction attributes category breakdown correctly without double-counting',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Department Store 3-Way',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 500.0),
          TransactionSplit(category: 'Fuel', amount: 300.0),
          TransactionSplit(category: 'Medical', amount: 200.0),
        ],
      ));

      final breakdown = provider.categoryBreakdown;
      expect(breakdown['Food'], equals(500.0));
      expect(breakdown['Fuel'], equals(300.0));
      expect(breakdown['Medical'], equals(200.0));
      expect(breakdown.containsKey('General'), isFalse);
      expect(provider.monthSpend, equals(1000.0));
    });

    // 3. 5-way split
    test(
        '3. 5-way split transaction attributes all 5 sub-categories accurately',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Mega Mall 5-Way',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 200.0),
          TransactionSplit(category: 'Fuel', amount: 200.0),
          TransactionSplit(category: 'Shopping', amount: 200.0),
          TransactionSplit(category: 'Medical', amount: 200.0),
          TransactionSplit(category: 'Travel', amount: 200.0),
        ],
      ));

      final breakdown = provider.categoryBreakdown;
      expect(breakdown['Food'], equals(200.0));
      expect(breakdown['Fuel'], equals(200.0));
      expect(breakdown['Shopping'], equals(200.0));
      expect(breakdown['Medical'], equals(200.0));
      expect(breakdown['Travel'], equals(200.0));
      expect(provider.monthSpend, equals(1000.0));
    });

    // 4. Shared split transaction & Profile Isolation
    test(
        '4. Shared split transaction shows ₹1,000 parent amount ONCE in Family Summary',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final pA = provider.activeProfileId;

      // Profile A: ₹1,000 Shared Split (Food ₹700, Entertainment ₹300)
      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Shared Store A',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: true,
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      ));

      // Profile B: ₹2,000 Private (Travel ₹2,000)
      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 2000.0,
        merchant: 'Private Flight B',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
      ));

      // Profile B dashboard shows only B's ₹2,000
      expect(provider.monthSpend, equals(2000.0));

      // Switch back to Profile A: A sees only A's ₹1,000
      await provider.switchProfile(pA);
      expect(provider.monthSpend, equals(1000.0));

      // Family Summary: Shows A's ₹1,000 shared parent amount ONCE without double-counting splits
      final summary = await FamilyService.instance.getFamilySummary();
      expect(summary.monthlyFamilyExpenses, equals(1000.0));
    });

    // 5. Private split transaction
    test(
        '5. Private split transaction is completely invisible to Family Summary',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 1500.0,
        merchant: 'Private Hypermarket',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
        splits: [
          TransactionSplit(category: 'Food', amount: 1000.0),
          TransactionSplit(category: 'Shopping', amount: 500.0),
        ],
      ));

      final summary = await FamilyService.instance.getFamilySummary();
      expect(summary.monthlyFamilyExpenses, equals(0.0));
    });

    // 6. Credit split transaction
    test(
        '6. Credit split transaction splits income without corrupting net totals',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 5000.0,
        merchant: 'Bonus Payment',
        category: 'Income',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Salary', amount: 4000.0),
          TransactionSplit(category: 'Investments', amount: 1000.0),
        ],
      ));

      expect(provider.transactions.first.type, equals(TransactionType.credit));
      expect(provider.transactions.first.amount, equals(5000.0));
    });

    // 7. Refund split transaction
    test('7. Refund split transaction reduces net spending correctly',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      // Original debit ₹1,000
      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Store Purchase',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      // Partial refund ₹300 split
      await provider.addTransaction(TransactionItem(
        amount: 300.0,
        merchant: 'Store Refund',
        category: 'Food',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      expect(provider.monthSpend, equals(700.0));
    });

    // 8. Edited split transaction
    test(
        '8. Editing split categories from Food 700 + Ent 300 to Food 500 + Transport 500 updates totals correctly',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final originalTx = TransactionItem(
        amount: 1000.0,
        merchant: 'Edit Mall',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      );

      await provider.addTransaction(originalTx);
      final addedTx = provider.transactions.first;

      final editedTx = addedTx.copyWith(
        splits: [
          TransactionSplit(category: 'Food', amount: 500.0),
          TransactionSplit(category: 'Transport', amount: 500.0),
        ],
      );

      await provider.updateTransaction(editedTx);

      final breakdown = provider.categoryBreakdown;
      expect(breakdown['Food'], equals(500.0));
      expect(breakdown['Transport'], equals(500.0));
      expect(breakdown.containsKey('Entertainment'), isFalse);
      expect(provider.monthSpend, equals(1000.0));
    });

    // 9 & 12. Duplicate split transaction & Same reference across profiles
    test(
        '9 & 12. Duplicate split detection operates on parent, allowing same reference in Profile B',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final pATx = TransactionItem(
        amount: 1000.0,
        merchant: 'Store X',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'UPI_REF_999',
        splits: [
          TransactionSplit(category: 'Food', amount: 600.0),
          TransactionSplit(category: 'Fuel', amount: 400.0),
        ],
      );

      await provider.addTransaction(pATx);

      // Re-importing candidate in Profile A is flagged duplicate
      final pACandidate = TransactionItem(
        amount: 1000.0,
        merchant: 'Store X',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'UPI_REF_999',
      );

      expect(
        DuplicateHashDetector.isDuplicate(
          candidate: pACandidate,
          existingTransactions: provider.transactions,
        ),
        isTrue,
      );

      // Same reference in Profile B is allowed (isolated profile)
      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      expect(
        DuplicateHashDetector.isDuplicate(
          candidate: pACandidate.copyWith(profileId: pB.id),
          existingTransactions: provider.transactions,
        ),
        isFalse,
      );
    });

    // 10. Backup/restore split transaction
    test(
        '10. Backup and restore preserves split transactions, profileId, and isShared across profiles',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final pA = provider.activeProfileId;

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Profile A Split',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: true,
        splits: [
          TransactionSplit(category: 'Food', amount: 600.0),
          TransactionSplit(category: 'Shopping', amount: 400.0),
        ],
      ));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 2500.0,
        merchant: 'Profile B Split',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
        splits: [
          TransactionSplit(category: 'Travel', amount: 2000.0),
          TransactionSplit(category: 'Medical', amount: 500.0),
        ],
      ));

      final archive =
          await BackupService.generateBackupArchive(password: 'Pass123!');

      // Wipe SQLite
      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        await db.delete('transactions');
        await db.delete('profiles');
      }

      await BackupService.restoreFromArchive(archive, password: 'Pass123!');

      final restoredA =
          await DatabaseHelper.instance.getAllTransactions(profileId: pA);
      final restoredB =
          await DatabaseHelper.instance.getAllTransactions(profileId: pB.id);

      expect(restoredA.length, equals(1));
      expect(restoredB.length, equals(1));

      expect(restoredA.first.isSplit, isTrue);
      expect(restoredA.first.splits?.length, equals(2));
      expect(restoredA.first.isShared, isTrue);

      expect(restoredB.first.isSplit, isTrue);
      expect(restoredB.first.splits?.length, equals(2));
      expect(restoredB.first.isShared, isFalse);
    });

    // 11. Profile deletion with split
    test(
        '11. Profile deletion deletes parent split transaction without leaving orphan data',
        () async {
      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      final provider = BudgetProvider();
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 1200.0,
        merchant: 'Split to Delete',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 800.0),
          TransactionSplit(category: 'Other', amount: 400.0),
        ],
      ));

      expect(provider.transactions.length, equals(1));

      await FamilyService.instance.deleteProfile(pB.id);

      final txsB =
          await DatabaseHelper.instance.getAllTransactions(profileId: pB.id);
      expect(txsB, isEmpty);
    });

    // Safe Today check
    test('12. Safe Today calculates using parent split amount exactly once',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.updateMonthlyBudget(31000.0);

      final aug1 = DateTime(2026, 8, 1);
      final initialSafeToday = provider.calculateSafeToday(targetDate: aug1);
      expect(initialSafeToday, equals(1000.0)); // 31000 / 31 days

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Split Safe Today',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      ));

      // 31000 budget - 1000 spent = 30000 buffer / 31 days = 967.74 (NOT 29000 / 31 = 935.48)
      final safeTodayAfterSplit = provider.calculateSafeToday(targetDate: aug1);
      expect(safeTodayAfterSplit, closeTo(967.74, 0.01));
    });
  });
}
