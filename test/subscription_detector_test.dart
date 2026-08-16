import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/subscription_detector.dart';
import 'package:sagiro/models/transaction.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('SubscriptionDetectorService Tests', () {
    test('Detects Netflix and Spotify subscriptions correctly', () {
      final txs = [
        TransactionItem(
            amount: 649,
            merchant: 'Netflix India',
            category: 'Entertainment',
            type: TransactionType.debit,
            source: TransactionSource.sms,
            date: DateTime(2026, 7, 1)),
        TransactionItem(
            amount: 649,
            merchant: 'Netflix India',
            category: 'Entertainment',
            type: TransactionType.debit,
            source: TransactionSource.sms,
            date: DateTime(2026, 8, 1)),
        TransactionItem(
            amount: 119,
            merchant: 'Spotify',
            category: 'Entertainment',
            type: TransactionType.debit,
            source: TransactionSource.sms,
            date: DateTime(2026, 8, 2)),
      ];

      final subs = SubscriptionDetectorService.detectSubscriptions(txs);

      expect(subs.length, equals(2));
      expect(subs.any((s) => s.merchant.contains('Netflix')), isTrue);
      expect(subs.any((s) => s.merchant.contains('Spotify')), isTrue);
    });

    test('Returns empty list when no subscription merchants exist', () {
      final txs = [
        TransactionItem(
            amount: 450,
            merchant: 'Swiggy',
            category: 'Food',
            type: TransactionType.debit,
            source: TransactionSource.sms,
            date: DateTime(2026, 8, 1)),
      ];

      final subs = SubscriptionDetectorService.detectSubscriptions(txs);

      expect(subs, isEmpty);
    });

    test('Returns empty list for empty transaction list', () {
      final subs = SubscriptionDetectorService.detectSubscriptions([]);

      expect(subs, isEmpty);
    });
  });
}
