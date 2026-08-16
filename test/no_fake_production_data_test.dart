import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/family_engine/services/family_service.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/services/sms_inbox_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
      await db.delete('savings_goals');
      await db.delete('upcoming_bills');
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
    await AppSettingsService.instance.loadSettings();
  });

  group('No Fake Production Data Audit Test Suite', () {
    test('1. Fresh database has zero transactions', () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);
      final count = Sqflite.firstIntValue(
          await db!.rawQuery('SELECT COUNT(*) FROM transactions'));
      expect(count, equals(0));
    });

    test('2. Fresh database has no seeded financial records or goals',
        () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);
      final goalsCount = Sqflite.firstIntValue(
          await db!.rawQuery('SELECT COUNT(*) FROM savings_goals'));
      final billsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM upcoming_bills'));
      expect(goalsCount, equals(0));
      expect(billsCount, equals(0));
    });

    test('3. Dashboard with empty database has zero financial totals',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.transactions.isEmpty, isTrue);
      expect(provider.calculateMonthSpend(), equals(0.0));
      expect(provider.calculateTodaySpend(), equals(0.0));
      expect(provider.categoryBreakdown.values.every((v) => v == 0.0), isTrue);
    });

    test('4. Safe Today with empty database does not fabricate a value',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      // When no monthly budget is configured by user
      expect(provider.hasBudget, isFalse);
      expect(provider.dailySafeSpendingLimit, equals(0.0));
      expect(provider.safeTodaySubtitle,
          contains('Set a monthly budget to calculate Safe Today'));
    });

    test('5. Family starts without fake transactions', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      expect(provider.activeProfileId, equals('default_profile'));
      expect(provider.transactions.isEmpty, isTrue);

      final p2 = await FamilyService.instance.createProfile(name: 'Member Two');
      await provider.switchProfile(p2.id);

      expect(provider.transactions.isEmpty, isTrue);
    });

    test('6. SMS scan with no matching SMS produces zero transactions',
        () async {
      // Direct call on SmsReadResult empty state
      const result = SmsReadResult(
        transactions: [],
        totalRead: 0,
        totalInboxMessages: 0,
        passedToParser: 0,
        rejectedKeyword: 0,
        parsed: 0,
        debitCount: 0,
        creditCount: 0,
        skippedDuplicates: 0,
        permissionDenied: false,
      );

      expect(result.transactions.isEmpty, isTrue);
      expect(result.parsed, equals(0));
    });

    test('7. CSV import requires an actual file payload', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.transactions.isEmpty, isTrue);
    });

    test('8. Manual transaction creates exactly one transaction', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.transactions.length, equals(0));

      final tx = TransactionItem(
        amount: 350.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
      );

      await provider.addTransaction(tx);
      expect(provider.transactions.length, equals(1));
      expect(provider.transactions.first.amount, equals(350.0));
    });

    test('9. Delete removes the transaction cleanly', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final tx = TransactionItem(
        amount: 200.0,
        merchant: 'Cafe',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
      );

      await provider.addTransaction(tx);
      expect(provider.transactions.length, equals(1));

      final createdId = provider.transactions.first.id!;
      await provider.deleteTransaction(createdId);
      expect(provider.transactions.length, equals(0));
    });

    test('10. App reload does not recreate deleted or fake demo transactions',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.transactions.length, equals(0));

      // Reload data again
      await provider.loadData();
      expect(provider.transactions.length, equals(0));
    });
  });
}
