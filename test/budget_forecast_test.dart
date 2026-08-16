import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/budget_forecast_service.dart';
import 'package:sagiro/models/transaction.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('BudgetForecastService Velocity Calculation', () {
    test('Calculates overspending pace velocity correctly', () {
      final now = DateTime.now();
      final txs = [
        TransactionItem(
            amount: 15000,
            merchant: 'Shopping',
            category: 'Shopping',
            type: TransactionType.debit,
            source: TransactionSource.manual,
            date: now,
            rawSms: null),
      ];

      final forecast = BudgetForecastService.calculateForecast(txs, 20000.0);

      expect(forecast.currentSpend, equals(15000.0));
      expect(forecast.monthlyBudget, equals(20000.0));
      expect(forecast.dailyVelocity,
          equals(15000.0 / (now.day == 0 ? 1 : now.day)));
      expect(forecast.predictedMonthEnd, greaterThanOrEqualTo(15000.0));
    });
  });
}
