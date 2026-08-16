import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/family_engine/models/family_models.dart';
import 'package:sagiro/family_engine/services/family_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
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
        await db.delete('family_budgets');
        await db.delete('family_goals');
      } catch (_) {}
    }
    await FamilyService.instance.ensureDefaultProfile();
    await FamilyService.instance
        .setActiveProfileId(FamilyService.kDefaultProfileId);
  });

  group('SAGIRO Family Workspace Master Audit & Privacy Suite', () {
    test('1. Primary profile is initialized by default and cannot be deleted',
        () async {
      final members = await FamilyService.instance.getAllProfiles();
      expect(members.isNotEmpty, isTrue);
      expect(members.first.id, equals(FamilyService.kDefaultProfileId));
      expect(members.first.name, equals('Primary Account'));

      expect(
        () => FamilyService.instance
            .deleteProfile(FamilyService.kDefaultProfileId),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('2. Add Family Member persists to SQLite', () async {
      final newMember = await FamilyService.instance.createProfile(
        name: 'Spouse',
        avatarEmoji: '👩',
        role: FamilyRole.adult,
      );

      expect(newMember.name, equals('Spouse'));
      expect(newMember.avatarEmoji, equals('👩'));

      final allProfiles = await FamilyService.instance.getAllProfiles();
      expect(allProfiles.length, equals(2));
      expect(allProfiles.any((p) => p.name == 'Spouse'), isTrue);
    });

    test('3. Private transaction isolation between profiles', () async {
      final spouse = await FamilyService.instance.createProfile(
        name: 'Spouse',
        avatarEmoji: '👩',
        role: FamilyRole.adult,
      );

      final db = await DatabaseHelper.instance.database;

      // Profile A (Primary) creates private ₹1,000 transaction
      final txPrimary = TransactionItem(
        amount: 1000.0,
        merchant: 'Primary Private Shopping',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: FamilyService.kDefaultProfileId,
        isShared: false,
      );
      await db!.insert('transactions', txPrimary.toMap());

      // Profile B (Spouse) creates private ₹2,000 transaction
      final txSpouse = TransactionItem(
        amount: 2000.0,
        merchant: 'Spouse Private Medical',
        category: 'Medical',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: spouse.id,
        isShared: false,
      );
      await db.insert('transactions', txSpouse.toMap());

      // Query Primary's private transactions
      final primaryRows = await db.query(
        'transactions',
        where: 'profileId = ?',
        whereArgs: [FamilyService.kDefaultProfileId],
      );
      expect(primaryRows.length, equals(1));
      expect(primaryRows.first['amount'], equals(1000.0));

      // Query Spouse's private transactions
      final spouseRows = await db.query(
        'transactions',
        where: 'profileId = ?',
        whereArgs: [spouse.id],
      );
      expect(spouseRows.length, equals(1));
      expect(spouseRows.first['amount'], equals(2000.0));

      // Family Summary should see 0 shared transactions
      final summary = await FamilyService.instance.getFamilySummary();
      expect(summary.sharedTransactionCount, equals(0));
      expect(summary.totalFamilyNetWorth, equals(0.0));
    });

    test(
        '4. Shared transaction visibility and live Family Net Position calculation',
        () async {
      final db = await DatabaseHelper.instance.database;

      // Shared Income ₹50,000
      final incomeTx = TransactionItem(
        amount: 50000.0,
        merchant: 'Household Salary',
        category: 'Salary',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: FamilyService.kDefaultProfileId,
        isShared: true,
      );
      await db!.insert('transactions', incomeTx.toMap());

      // Shared Expense ₹15,000
      final expenseTx = TransactionItem(
        amount: 15000.0,
        merchant: 'House Rent',
        category: 'Rent',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: FamilyService.kDefaultProfileId,
        isShared: true,
      );
      await db.insert('transactions', expenseTx.toMap());

      final summary = await FamilyService.instance.getFamilySummary();
      expect(summary.sharedTransactionCount, equals(2));
      expect(summary.monthlyFamilyIncome, equals(50000.0));
      expect(summary.monthlyFamilyExpenses, equals(15000.0));
      expect(summary.totalFamilyNetWorth, equals(35000.0));
      expect(summary.monthlyFamilySavings, equals(35000.0));
      // Health score: ((50000 - 15000) / 50000) * 100 = 70/100
      expect(summary.familyHealthScore, equals(70));
    });

    test('5. Shared Household Budgets creation, listing & live tracking',
        () async {
      await FamilyService.instance.addSharedBudget(
        category: 'Groceries',
        limitAmount: 10000.0,
      );

      final db = await DatabaseHelper.instance.database;

      // Add a shared grocery expense of ₹4,000
      final groceryTx = TransactionItem(
        amount: 4000.0,
        merchant: 'Supermarket',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: FamilyService.kDefaultProfileId,
        isShared: true,
      );
      await db!.insert('transactions', groceryTx.toMap());

      final budgets = await FamilyService.instance.getSharedBudgets();
      expect(budgets.length, equals(1));
      expect(budgets.first.category, equals('Groceries'));
      expect(budgets.first.limitAmount, equals(10000.0));
      expect(budgets.first.totalSpent, equals(4000.0));
      expect(budgets.first.remaining, equals(6000.0));
    });

    test('6. Shared Household Goals creation and member contributions',
        () async {
      await FamilyService.instance.addSharedGoal(
        title: 'Emergency Fund',
        targetAmount: 100000.0,
      );

      var goals = await FamilyService.instance.getSharedGoals();
      expect(goals.length, equals(1));
      expect(goals.first.title, equals('Emergency Fund'));
      expect(goals.first.totalSaved, equals(0.0));

      // Contribute ₹25,000 as Primary Account
      await FamilyService.instance.contributeToSharedGoal(
        goalId: goals.first.id,
        memberName: 'Primary Account',
        amount: 25000.0,
      );

      goals = await FamilyService.instance.getSharedGoals();
      expect(goals.first.totalSaved, equals(25000.0));
      expect(goals.first.progressPercentage, equals(25.0));
    });

    test('7. Recent Shared Activity feed', () async {
      final db = await DatabaseHelper.instance.database;

      final sharedTx = TransactionItem(
        amount: 3200.0,
        merchant: 'Airtel Broadband',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: FamilyService.kDefaultProfileId,
        isShared: true,
      );
      await db!.insert('transactions', sharedTx.toMap());

      final activities = await FamilyService.instance.getRecentSharedActivity();
      expect(activities.isNotEmpty, isTrue);
      expect(activities.first.profileName, equals('Primary Account'));
      expect(activities.first.amount, equals(3200.0));
    });

    test('8. Deleting secondary profile cleans up its private data safely',
        () async {
      final spouse = await FamilyService.instance.createProfile(
        name: 'Spouse',
        avatarEmoji: '👩',
        role: FamilyRole.adult,
      );

      final db = await DatabaseHelper.instance.database;
      final txSpouse = TransactionItem(
        amount: 500.0,
        merchant: 'Spouse Item',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: spouse.id,
        isShared: false,
      );
      await db!.insert('transactions', txSpouse.toMap());

      // Delete Spouse
      await FamilyService.instance.deleteProfile(spouse.id);

      final allProfiles = await FamilyService.instance.getAllProfiles();
      expect(allProfiles.length, equals(1));
      expect(allProfiles.first.id, equals(FamilyService.kDefaultProfileId));

      final spouseTxs = await db.query(
        'transactions',
        where: 'profileId = ?',
        whereArgs: [spouse.id],
      );
      expect(spouseTxs.isEmpty, isTrue);
    });
  });
}
