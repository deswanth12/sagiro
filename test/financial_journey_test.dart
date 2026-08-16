import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/models/financial_health_score.dart';
import 'package:sagiro/services/financial_journey_service.dart';
import 'package:sagiro/services/habit_loop_service.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Financial Journey & Health Score Tests', () {
    test('Calculates 0-100 Financial Health Score correctly', () {
      final score = FinancialHealthScore.calculate(
        monthSpend: 15000.0,
        monthlyBudget: 25000.0,
        totalTransactions: 20,
        noSpendDays: 5,
        totalSubscriptionCount: 2,
        foodSpend: 3000.0,
      );

      expect(score.overallScore, greaterThanOrEqualTo(80));
      expect(score.overallScore, lessThanOrEqualTo(100));
      expect(score.ratingText, contains('Financial'));
    });

    test(
        'FinancialJourneyService calculateFinancialHealthScore returns strengths and focus points',
        () {
      final txs = [
        TransactionItem(
          amount: 50000.0,
          merchant: 'HDFC Bank Salary',
          category: 'Salary',
          type: TransactionType.credit,
          source: TransactionSource.sms,
          date: DateTime.now(),
        ),
        TransactionItem(
          amount: 1200.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime.now(),
        ),
      ];

      final healthResult =
          FinancialJourneyService.calculateFinancialHealthScore(
        transactions: txs,
        monthlyBudget: 30000.0,
        monthSpend: 1200.0,
      );

      expect(healthResult.score, greaterThanOrEqualTo(70));
      expect(healthResult.strengths, isNotEmpty);
      expect(healthResult.focusPoints, isNotEmpty);
    });

    test('Generates dynamic timeline feed items correctly', () {
      final txs = [
        TransactionItem(
          amount: 85000.0,
          merchant: 'HDFC Bank Salary',
          category: 'Salary',
          type: TransactionType.credit,
          source: TransactionSource.sms,
          date: DateTime.now(),
        ),
        TransactionItem(
          amount: 2500.0,
          merchant: 'Amazon India',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];

      final timeline = FinancialJourneyService.generateTimelineFeed(
        transactions: txs,
        monthlyBudget: 30000.0,
        monthSpend: 2500.0,
      );

      expect(timeline, isNotEmpty);
      expect(timeline.any((t) => t.title.contains('Income')), isTrue);
      expect(timeline.any((t) => t.title.contains('Expense')), isTrue);
    });

    test('Evaluates 7 gamified achievement badges', () {
      final txs = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Grocery Store',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ];

      final achievements = FinancialJourneyService.evaluateAchievements(
        transactions: txs,
        monthlyBudget: 20000.0,
        monthSpend: 500.0,
        noSpendDaysCount: 6,
      );

      expect(achievements.length, equals(7));
      expect(
          achievements.any((a) => a.title == 'First Week Completed'), isTrue);
      expect(achievements.any((a) => a.title == 'Budget Master'), isTrue);
    });

    test('Classifies 5 Money Weather Tiers correctly', () {
      final sunny = HabitLoopService.getWeatherForecast(
        todaySpend: 0,
        dailySafeLimit: 1000,
        predictedMonthEnd: 15000,
        monthlyBudget: 25000,
        hasTransactions: true,
      );

      expect(sunny.status, contains('Sunny'));

      final storm = HabitLoopService.getWeatherForecast(
        todaySpend: 2500,
        dailySafeLimit: 1000,
        predictedMonthEnd: 35000,
        monthlyBudget: 25000,
        hasTransactions: true,
      );

      expect(storm.status, contains('Storm'));
    });
  });
}
