import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('Safe Today No Hardcoded Fallback Tests', () {
    test('Default budget starts at 0.0 when not set in database', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      expect(provider.monthlyBudget, equals(0.0));
      expect(provider.hasBudget, isFalse);
      expect(provider.dailySafeSpendingLimit, equals(0.0));
    });

    test('Safe Today limit is calculated deterministically when budget is set',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(30000.0);

      expect(provider.monthlyBudget, equals(30000.0));
      expect(provider.hasBudget, isTrue);

      final now = DateTime.now();
      final totalDays = DateTime(now.year, now.month + 1, 0).day;
      final remainingDays = (totalDays - now.day + 1).clamp(1, 31);
      final expectedDaily = 30000.0 / remainingDays;

      expect(provider.dailySafeSpendingLimit, equals(expectedDaily));
    });

    test(
        'Safe Today subtitle returns honest empty state message when budget is 0',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      expect(provider.safeTodaySubtitle,
          equals('Set a monthly budget to calculate Safe Today.'));
    });

    test(
        'Safe Today subtitle returns "Daily limit based on monthly budget" when budget exists but 0 transactions',
        () async {
      final provider = BudgetProvider();
      await provider.updateMonthlyBudget(60000.0);

      expect(provider.safeTodaySubtitle,
          equals('Daily limit based on monthly budget'));
    });
  });
}
