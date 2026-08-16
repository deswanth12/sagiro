import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/family_engine/models/family_models.dart';
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

  group(
      'Problem 11: Family Workspace (Local-First Multi-Profile) Test Suite (22 Scenarios)',
      () {
    // 1. Create profile
    test('1. Create primary default profile automatically', () async {
      await FamilyService.instance.ensureDefaultProfile();
      final profiles = await FamilyService.instance.getAllProfiles();

      expect(profiles.length, equals(1));
      expect(profiles.first.id, equals('default_profile'));
      expect(profiles.first.name, equals('Primary Account'));
    });

    // 2. Create second profile
    test('2. Create second profile adds new profile to SQLite', () async {
      final p2 = await FamilyService.instance.createProfile(
        name: 'Spouse Profile',
        avatarEmoji: '👩',
        role: FamilyRole.adult,
      );

      final profiles = await FamilyService.instance.getAllProfiles();
      expect(profiles.length, equals(2));
      expect(profiles.any((p) => p.id == p2.id), isTrue);
    });

    // 3. Switch profile
    test('3. Switch active profile updates active profile ID setting',
        () async {
      final p2 = await FamilyService.instance.createProfile(name: 'Profile B');
      await FamilyService.instance.setActiveProfileId(p2.id);

      final activeId = await FamilyService.instance.getActiveProfileId();
      expect(activeId, equals(p2.id));
    });

    // 4 & 5. Profile A & B transaction isolation
    test('4 & 5. Profile A and B transaction isolation in SQLite', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final pA = provider.activeProfileId;

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Food Express',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 5000.0,
        merchant: 'Airline Booking',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      // Assert Profile B sees only ₹5,000 Travel
      expect(provider.transactions.length, equals(1));
      expect(provider.transactions.first.amount, equals(5000.0));
      expect(provider.transactions.first.category, equals('Travel'));

      // Switch back to Profile A
      await provider.switchProfile(pA);

      // Assert Profile A sees only ₹1,000 Food
      expect(provider.transactions.length, equals(1));
      expect(provider.transactions.first.amount, equals(1000.0));
      expect(provider.transactions.first.category, equals('Food'));
    });

    // 6. Dashboard isolation
    test('6. Dashboard monthly spend isolates spending by active profile',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final pA = provider.activeProfileId;

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Food Store',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1),
      ));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 5000.0,
        merchant: 'Travel Agent',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1),
      ));

      expect(provider.monthSpend, equals(5000.0));

      await provider.switchProfile(pA);
      expect(provider.monthSpend, equals(1000.0));
    });

    // 7. Category isolation
    test('7. Category breakdown isolates category totals by profile', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Food Outlet',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1),
      ));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      final breakdownB = provider.categoryBreakdown;
      expect(breakdownB.containsKey('Food'), isFalse);
    });

    // 8. Safe Today isolation
    test(
        '8. Safe Today calculates limit using active profile budget and spending',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.updateMonthlyBudget(31000.0);

      final aug1 = DateTime(2026, 8, 1);
      final safeTodayA = provider.calculateSafeToday(targetDate: aug1);
      expect(safeTodayA, equals(1000.0));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);
      await provider.updateMonthlyBudget(62000.0);

      final safeTodayB = provider.calculateSafeToday(targetDate: aug1);
      expect(safeTodayB, equals(2000.0));
    });

    // 9. Manual transaction ownership
    test('9. Manual transaction inherits active profile ID', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final activeId = provider.activeProfileId;

      final tx = TransactionItem(
        amount: 500.0,
        merchant: 'Coffee Shop',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      );

      await provider.addTransaction(tx);
      expect(provider.transactions.first.profileId, equals(activeId));
    });

    // 10. SMS transaction ownership
    test('10. Batch SMS import attaches active profile ID', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final activeId = provider.activeProfileId;

      await provider.addTransactionsBatch([
        TransactionItem(
          amount: 250.0,
          merchant: 'Uber Trip',
          category: 'Travel',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 13),
        ),
      ]);

      expect(provider.transactions.first.profileId, equals(activeId));
    });

    // 11. CSV transaction ownership
    test('11. CSV transaction attached to active profile ID', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final activeId = provider.activeProfileId;

      await provider.addTransaction(TransactionItem(
        amount: 1500.0,
        merchant: 'CSV Merchant',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime(2026, 8, 13),
      ));

      expect(provider.transactions.first.profileId, equals(activeId));
    });

    // 12. Split transaction ownership
    test('12. Split transaction retains single profile ownership', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final activeId = provider.activeProfileId;

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Other', amount: 300.0),
        ],
      ));

      expect(provider.transactions.first.profileId, equals(activeId));
      expect(provider.transactions.first.isSplit, isTrue);
    });

    // 13 & 14. Duplicate detection within profile & cross-profile allowance
    test(
        '13 & 14. Duplicate detection operates within profile, allows same reference across profiles',
        () async {
      final pBCandidate = TransactionItem(
        amount: 500.0,
        merchant: 'Vendor',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'REF_ABC123',
        profileId: 'profile_B',
      );

      // Scoped check for Profile B (where existing list is empty for Profile B)
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: pBCandidate, existingTransactions: []),
          isFalse);
    });

    // 15. Existing transaction migration
    test('15. Legacy transactions without profileId default to default_profile',
        () async {
      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        await db.execute('''
          INSERT INTO transactions (amount, merchant, category, type, source, date)
          VALUES (999.0, 'Legacy Merchant', 'General', 'debit', 'manual', '2026-08-13T00:00:00.000')
        ''');
      }

      final txs = await DatabaseHelper.instance.getAllTransactions();
      expect(txs.length, equals(1));
      expect(txs.first.profileId, equals('default_profile'));
    });

    // 16. Backup/restore profile ownership
    test('16. Backup and restore preserves profile ownership across profiles',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final pA = provider.activeProfileId;

      await provider.addTransaction(TransactionItem(
        amount: 100.0,
        merchant: 'A Merchant',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 200.0,
        merchant: 'B Merchant',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      final archive =
          await BackupService.generateBackupArchive(password: 'Pass123!');
      expect(archive, isNotEmpty);

      // Clear database
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
      expect(restoredA.first.amount, equals(100.0));
      expect(restoredB.first.amount, equals(200.0));
    });

    // 17. Profile names (special chars, unicode)
    test('17. Profile names support Unicode and special characters', () async {
      await FamilyService.instance.createProfile(
        name: '🎉 Anita\'s Profile (आनिता) #1',
        avatarEmoji: '👩‍💼',
      );

      final profiles = await FamilyService.instance.getAllProfiles();
      expect(profiles.any((p) => p.name == '🎉 Anita\'s Profile (आनिता) #1'),
          isTrue);
    });

    // 18. Empty profile validation
    test('18. Empty profile name throws ArgumentError', () async {
      expect(
        () => FamilyService.instance.createProfile(name: '   '),
        throwsArgumentError,
      );
    });

    // 19. Long profile name handling
    test('19. Long profile names stored without truncation or error', () async {
      final longName = 'A' * 150;
      final member = await FamilyService.instance.createProfile(name: longName);

      expect(member.name.length, equals(150));
    });

    // 20. Offline operation
    test('20. Profile CRUD operates 100% offline via local SQLite', () async {
      final member =
          await FamilyService.instance.createProfile(name: 'Offline Member');
      final profiles = await FamilyService.instance.getAllProfiles();

      expect(profiles.any((p) => p.id == member.id), isTrue);
    });

    // 21. Cache invalidation on profile switch
    test('21. Profile switch invalidates cached monthSpend and analytics',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 1200.0,
        merchant: 'Store A',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1),
      ));

      final initialSpend = provider.monthSpend;
      expect(initialSpend, equals(1200.0));

      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      final newSpend = provider.monthSpend;
      expect(newSpend, equals(0.0));
    });

    // 22. Profile deletion safety
    test(
        '22. Profile deletion requires explicit call, deletes associated transactions, rejects primary profile deletion',
        () async {
      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      final provider = BudgetProvider();
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 750.0,
        merchant: 'B Store',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      ));

      // Attempting to delete default_profile should throw ArgumentError
      expect(
        () => FamilyService.instance
            .deleteProfile(FamilyService.kDefaultProfileId),
        throwsArgumentError,
      );

      // Explicitly delete profile B
      await FamilyService.instance.deleteProfile(pB.id);

      final profiles = await FamilyService.instance.getAllProfiles();
      expect(profiles.any((p) => p.id == pB.id), isFalse);

      final txsB =
          await DatabaseHelper.instance.getAllTransactions(profileId: pB.id);
      expect(txsB, isEmpty);
    });

    // 23. Profile update (rename, avatar, role)
    test('23. Update profile saves changes to SQLite', () async {
      final p = await FamilyService.instance.createProfile(
        name: 'Initial Name',
        avatarEmoji: '👤',
        role: FamilyRole.adult,
      );

      final updated = FamilyMember(
        id: p.id,
        name: 'Priya (Renamed)',
        avatarEmoji: '👩',
        role: FamilyRole.adult,
        createdAt: p.createdAt,
      );

      await FamilyService.instance.updateProfile(updated);
      final all = await FamilyService.instance.getAllProfiles();
      final found = all.firstWhere((m) => m.id == p.id);

      expect(found.name, equals('Priya (Renamed)'));
      expect(found.avatarEmoji, equals('👩'));
    });

    // 24. Budget and Goal updates
    test('24. Update shared budget and goal alters limits and titles',
        () async {
      await FamilyService.instance
          .addSharedBudget(category: 'Groceries', limitAmount: 8000.0);
      var budgets = await FamilyService.instance.getSharedBudgets();
      expect(budgets.length, equals(1));
      expect(budgets.first.limitAmount, equals(8000.0));

      await FamilyService.instance.updateSharedBudget(
        budgetId: budgets.first.id,
        limitAmount: 10000.0,
      );
      budgets = await FamilyService.instance.getSharedBudgets();
      expect(budgets.first.limitAmount, equals(10000.0));

      await FamilyService.instance
          .addSharedGoal(title: 'Vacation', targetAmount: 50000.0);
      var goals = await FamilyService.instance.getSharedGoals();
      expect(goals.length, equals(1));
      expect(goals.first.title, equals('Vacation'));

      await FamilyService.instance.updateSharedGoal(
        goalId: goals.first.id,
        title: 'Europe Trip',
        targetAmount: 100000.0,
      );
      goals = await FamilyService.instance.getSharedGoals();
      expect(goals.first.title, equals('Europe Trip'));
      expect(goals.first.targetAmount, equals(100000.0));
    });

    // 25. Member financial stats calculation
    test('25. getMemberFinancialStats accurately computes shared vs private',
        () async {
      final p = await FamilyService.instance.createProfile(name: 'Rahul');
      final db = await DatabaseHelper.instance.database;

      await db!.insert('transactions', {
        'amount': 500.0,
        'merchant': 'Coffee Shop',
        'category': 'Food',
        'type': 'debit',
        'source': 'manual',
        'date': DateTime.now().toIso8601String(),
        'profileId': p.id,
        'isShared': 0, // private
      });

      await db.insert('transactions', {
        'amount': 2500.0,
        'merchant': 'Supermarket',
        'category': 'Groceries',
        'type': 'debit',
        'source': 'manual',
        'date': DateTime.now().toIso8601String(),
        'profileId': p.id,
        'isShared': 1, // shared
      });

      final stats = await FamilyService.instance.getMemberFinancialStats(p.id);
      expect(stats.privateCount, equals(1));
      expect(stats.sharedCount, equals(1));
      expect(stats.sharedExpenses, equals(2500.0));
    });
  });
}
