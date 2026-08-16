import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/models/upcoming_bill.dart';
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
      await db.delete('upcoming_bills');
    }
  });

  group('Problem 9: Safe Today Data Validation Test Suite', () {
    test('1. No monthly budget set returns 0.0 Safe Today', () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(0.0);

      expect(provider.hasBudget, isFalse);
      expect(provider.dailySafeSpendingLimit, equals(0.0));
      expect(provider.safeTodaySubtitle, contains('Set a monthly budget'));
    });

    test(
        '2. Zero transactions on 31-day month (Aug 1st: 31 days remaining, ₹31,000 budget)',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(31000.0);
      final aug1 = DateTime(2026, 8, 1);

      final safeToday = provider.calculateSafeToday(targetDate: aug1);
      expect(safeToday, equals(1000.0)); // ₹31,000 / 31 days = ₹1,000 / day
    });

    test(
        '3. Middle of month (Aug 15th: 17 days remaining, ₹31,000 budget, 0 spend)',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(31000.0);
      final aug15 = DateTime(2026, 8, 15);

      final safeToday = provider.calculateSafeToday(targetDate: aug15);
      // 31 - 15 + 1 = 17 remaining days. 31000 / 17 = 1823.5294...
      expect(safeToday, closeTo(1823.53, 0.01));
    });

    test(
        '4. Last day of month (Aug 31st: 1 day remaining, ₹31,000 budget, ₹30,000 spent)',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(31000.0);
      final aug31 = DateTime(2026, 8, 31);

      await provider.addTransaction(TransactionItem(
        amount: 30000.0,
        merchant: 'Shopping',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug31,
      ));

      final safeToday = provider.calculateSafeToday(targetDate: aug31);
      // Buffer = 31000 - 30000 = 1000. Remaining days = 1. Safe Today = 1000.0
      expect(safeToday, equals(1000.0));
    });

    test('5. Budget exceeded clamps Safe Today to 0.0 (Never negative)',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(10000.0);
      final aug15 = DateTime(2026, 8, 15);

      await provider.addTransaction(TransactionItem(
        amount: 15000.0,
        merchant: 'Overspend Store',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug15,
      ));

      final safeToday = provider.calculateSafeToday(targetDate: aug15);
      expect(safeToday, equals(0.0));
    });

    test('6. Fixed bills deduct from available buffer', () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(31000.0);
      final aug1 = DateTime(2026, 8, 1);

      await provider.addUpcomingBill(UpcomingBill(
        id: 'bill1',
        title: 'Electricity',
        amount: 6200.0,
        dueDate: aug1,
        providerEmoji: '⚡',
        category: 'Bills',
      ));

      // Buffer = 31000 - 6200 = 24800. Remaining days = 31. Safe Today = 24800 / 31 = 800.0
      final safeToday = provider.calculateSafeToday(targetDate: aug1);
      expect(safeToday, equals(800.0));
    });

    test('7. Credits and Refunds reduce net month spend, increasing Safe Today',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(31000.0);
      final aug1 = DateTime(2026, 8, 1);

      await provider.addTransaction(TransactionItem(
        amount: 10000.0,
        merchant: 'Flight Booking',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: aug1,
      ));

      await provider.addTransaction(TransactionItem(
        amount: 3100.0,
        merchant: 'Flight Refund',
        category: 'Travel',
        type: TransactionType.credit,
        source: TransactionSource.manual,
        date: aug1,
      ));

      final netSpend = provider.calculateMonthSpend(targetDate: aug1);
      expect(netSpend, equals(6900.0)); // 10000 - 3100 = 6900 net spend

      // Buffer = 31000 - 6900 = 24100. Remaining days = 31. Safe Today = 24100 / 31 = 777.419...
      final safeToday = provider.calculateSafeToday(targetDate: aug1);
      expect(safeToday, closeTo(777.42, 0.01));
    });

    test('8. February (non-leap year 28 days vs leap year 29 days)', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.updateMonthlyBudget(28000.0);

      final feb1NonLeap = DateTime(2027, 2, 1); // 2027 is non-leap (28 days)
      final safeTodayNonLeap =
          provider.calculateSafeToday(targetDate: feb1NonLeap);
      expect(safeTodayNonLeap, equals(1000.0)); // 28000 / 28 = 1000.0

      await provider.updateMonthlyBudget(29000.0);
      final feb1Leap = DateTime(2028, 2, 1); // 2028 is leap year (29 days)
      final safeTodayLeap = provider.calculateSafeToday(targetDate: feb1Leap);
      expect(safeTodayLeap, equals(1000.0)); // 29000 / 29 = 1000.0
    });

    test(
        '9. Transactions at midnight (00:00:00) and 23:59:59 parse correctly in local month',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(30000.0);
      final midnight = DateTime(2026, 8, 1, 0, 0, 0);
      final endOfDay = DateTime(2026, 8, 1, 23, 59, 59);

      await provider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'Midnight Coffee',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: midnight,
      ));

      await provider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'Late Night Diner',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: endOfDay,
      ));

      final todaySpend =
          provider.calculateTodaySpend(targetDate: DateTime(2026, 8, 1));
      expect(todaySpend, equals(1000.0));
    });
  });
}
