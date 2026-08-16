import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/monthly_story_service.dart';
import 'package:sagiro/models/transaction.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('MonthlyStoryService Tests', () {
    test('Generates story with zero transactions correctly (empty state)', () {
      final story = MonthlyStoryService.generateStory([], 25000.0);

      expect(story.hasData, isFalse);
      expect(story.totalSpent, equals(0.0));
      expect(story.topMerchant, equals('None'));
      expect(story.topCategory, equals('None'));
      expect(story.monthOverMonthChangePct, isNull);
      expect(story.totalSaved, isNull);
    });

    test('Calculates real monthly spend and top merchant correctly', () {
      final now = DateTime.now();
      final txs = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
        ),
        TransactionItem(
          amount: 1500.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
        ),
      ];

      final story = MonthlyStoryService.generateStory(txs, 25000.0);

      expect(story.hasData, isTrue);
      expect(story.totalSpent, equals(2000.0));
      expect(story.topMerchant, equals('Swiggy'));
      expect(story.topMerchantAmount, equals(2000.0));
      expect(story.topCategory, equals('Food'));
      expect(story.totalSaved, equals(23000.0));
      expect(story.monthOverMonthChangePct, isNull);
    });

    test(
        'Calculates real month-over-month percentage when previous month data exists',
        () {
      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 15);

      final txs = [
        TransactionItem(
          amount: 1000.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: prevMonth,
        ),
        TransactionItem(
          amount: 1500.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
        ),
      ];

      final story = MonthlyStoryService.generateStory(txs, 25000.0);

      expect(story.monthOverMonthChangePct, isNotNull);
      expect(story.monthOverMonthChangePct, closeTo(50.0, 0.1));
      expect(story.isIncreaseFromLastMonth, isTrue);
    });
  });
}
