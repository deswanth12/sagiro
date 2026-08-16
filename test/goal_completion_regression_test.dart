import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/savings_goal.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/database_helper.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  setUp(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('Goal Completion & Data Integrity Regression Unit Tests', () {
    test('TEST 1: New user has zero goals initially', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.savingsGoals.isEmpty, isTrue);
    });

    test(
        'TEST 2: Goal created with Target 50,000 and Current 0 is NOT COMPLETED',
        () async {
      final goal = SavingsGoal(
        id: 'goal_laptop_1',
        title: 'Laptop',
        targetAmount: 50000.0,
        currentAmount: 0.0,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        emoji: '💻',
      );

      expect(goal.isCompleted, isFalse);
      expect(goal.progress, equals(0.0));
      expect(goal.progressPct, equals(0));
    });

    test('TEST 3: Adding 25,000 to 50,000 target leaves goal NOT COMPLETED',
        () async {
      final goal = SavingsGoal(
        id: 'goal_laptop_1',
        title: 'Laptop',
        targetAmount: 50000.0,
        currentAmount: 25000.0,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        emoji: '💻',
      );

      expect(goal.isCompleted, isFalse);
      expect(goal.progress, equals(0.5));
      expect(goal.progressPct, equals(50));
    });

    test('TEST 4: Reaching 50,000 of 50,000 target marks goal COMPLETED',
        () async {
      final goal = SavingsGoal(
        id: 'goal_laptop_1',
        title: 'Laptop',
        targetAmount: 50000.0,
        currentAmount: 50000.0,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        emoji: '💻',
      );

      expect(goal.isCompleted, isTrue);
      expect(goal.progress, equals(1.0));
      expect(goal.progressPct, equals(100));
    });

    test('TEST 5: Exceeding target (60,000 / 50,000) keeps goal COMPLETED',
        () async {
      final goal = SavingsGoal(
        id: 'goal_laptop_1',
        title: 'Laptop',
        targetAmount: 50000.0,
        currentAmount: 60000.0,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        emoji: '💻',
      );

      expect(goal.isCompleted, isTrue);
      expect(goal.progress, equals(1.0));
      expect(goal.progressPct, equals(100));
    });

    test('TEST 6: Deleting Laptop goal removes it cleanly', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addSavingsGoal(SavingsGoal(
        id: 'goal_laptop_1',
        title: 'Laptop',
        targetAmount: 50000.0,
        currentAmount: 0.0,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        emoji: '💻',
      ));

      expect(provider.savingsGoals.length, equals(1));

      await provider.deleteSavingsGoal('goal_laptop_1');
      expect(provider.savingsGoals.isEmpty, isTrue);
    });

    test('TEST 7: Uncreated Emergency Fund does not exist in provider state',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final hasEmergency = provider.savingsGoals
          .any((g) => g.title.toLowerCase().contains('emergency'));
      expect(hasEmergency, isFalse);
    });

    test('TEST 8: Empty database exhibits zero goals state', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.savingsGoals, isEmpty);
    });

    test(
        'TEST 9: Reloading BudgetProvider preserves correct goal completion state',
        () async {
      final provider1 = BudgetProvider();
      await provider1.loadData();

      await provider1.addSavingsGoal(SavingsGoal(
        id: 'goal_car_1',
        title: 'Car Fund',
        targetAmount: 300000.0,
        currentAmount: 150000.0,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        emoji: '🚗',
      ));

      // Reload provider from DB
      final provider2 = BudgetProvider();
      await provider2.loadData();

      expect(provider2.savingsGoals.length, equals(1));
      final goal = provider2.savingsGoals.first;
      expect(goal.title, equals('Car Fund'));
      expect(goal.isCompleted, isFalse);
      expect(goal.progressPct, equals(50));
    });

    test(
        'TEST 10: Zero or invalid target amount never produces COMPLETED state',
        () {
      final zeroTargetGoal = SavingsGoal(
        id: 'goal_zero_1',
        title: 'Zero Target',
        targetAmount: 0.0,
        currentAmount: 0.0,
        targetDate: DateTime.now(),
        emoji: '🎯',
      );

      expect(zeroTargetGoal.isCompleted, isFalse);
    });
  });
}
