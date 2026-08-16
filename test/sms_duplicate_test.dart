import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/document_engine/duplicate/duplicate_hash_detector.dart';
import 'package:sagiro/models/transaction.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Problem 6: 14 Duplicate Scenarios Test Suite', () {
    // 1. Exact same SMS twice
    test('1. Exact same SMS twice is detected as duplicate', () {
      final tx1 = TransactionItem(
        amount: 450.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 13, 15),
        transactionReference: 'UPI987654321',
      );
      final tx2 = TransactionItem(
        amount: 450.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 13, 15),
        transactionReference: 'UPI987654321',
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: tx2, existingTransactions: [tx1]),
          isTrue);
    });

    // 2. Same transaction with different SMS wording
    test(
        '2. Same transaction with different SMS wording but same UTR is detected as duplicate',
        () {
      final tx1 = TransactionItem(
        amount: 1200.0,
        merchant: 'Zomato',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        notes: 'HDFC Bank • Ref: UTR55443322',
        transactionReference: 'UTR55443322',
      );
      final tx2 = TransactionItem(
        amount: 1200.0,
        merchant: 'Zomato Ltd',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'UTR55443322',
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: tx2, existingTransactions: [tx1]),
          isTrue);
    });

    // 3. Same UPI/reference twice
    test('3. Same UPI reference twice is detected as duplicate', () {
      final tx1 = TransactionItem(
        amount: 250.0,
        merchant: 'Uber',
        category: 'Transport',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: '051939321770',
      );
      final tx2 = TransactionItem(
        amount: 250.0,
        merchant: 'Uber Rides',
        category: 'Transport',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: '051939321770',
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: tx2, existingTransactions: [tx1]),
          isTrue);
    });

    // 4. Same transaction without reference scanned twice
    test(
        '4. Same transaction without reference scanned twice is detected as duplicate',
        () {
      final tx1 = TransactionItem(
        amount: 300.0,
        merchant: 'Local Vendor',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 10, 0),
      );
      final tx2 = TransactionItem(
        amount: 300.0,
        merchant: 'Local Vendor',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 10, 0),
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: tx2, existingTransactions: [tx1]),
          isTrue);
    });

    // 5. Two legitimate ₹500 transactions on the same day at different times
    test(
        '5. Two legitimate ₹500 transactions on same day at different times are KEPT SEPARATE',
        () {
      final lunch = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 13, 15), // 1:15 PM Lunch
      );
      final dinner = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 20, 30), // 8:30 PM Dinner (>15 min apart)
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: dinner, existingTransactions: [lunch]),
          isFalse);
    });

    // 6. Two legitimate transactions at the same merchant
    test(
        '6. Two legitimate transactions at same merchant with different amounts are KEPT SEPARATE',
        () {
      final tx1 = TransactionItem(
        amount: 150.0,
        merchant: 'Starbucks',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 9, 0),
      );
      final tx2 = TransactionItem(
        amount: 450.0,
        merchant: 'Starbucks',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13, 16, 0),
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: tx2, existingTransactions: [tx1]),
          isFalse);
    });

    // 7. Same amount but different merchants
    test('7. Same amount but different merchants are KEPT SEPARATE', () {
      final txSwiggy = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
      );
      final txUber = TransactionItem(
        amount: 500.0,
        merchant: 'Uber',
        category: 'Transport',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: txUber, existingTransactions: [txSwiggy]),
          isFalse);
    });

    // 8. Same amount and merchant on different dates
    test('8. Same amount and merchant on different dates are KEPT SEPARATE',
        () {
      final day1 = TransactionItem(
        amount: 500.0,
        merchant: 'Petrol Pump',
        category: 'Fuel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 12),
      );
      final day2 = TransactionItem(
        amount: 500.0,
        merchant: 'Petrol Pump',
        category: 'Fuel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: day2, existingTransactions: [day1]),
          isFalse);
    });

    // 9. Refund of previous transaction
    test(
        '9. Refund of a previous transaction is KEPT SEPARATE (Credit vs Debit)',
        () {
      final debitTx = TransactionItem(
        amount: 450.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
      );
      final refundTx = TransactionItem(
        amount: 450.0,
        merchant: 'Swiggy Refund',
        category: 'Food',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: refundTx, existingTransactions: [debitTx]),
          isFalse);
    });

    // 10. Reversal of previous transaction
    test(
        '10. Reversal of previous transaction is KEPT SEPARATE (Credit vs Debit)',
        () {
      final debitTx = TransactionItem(
        amount: 999.0,
        merchant: 'Myntra',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
      );
      final reversalTx = TransactionItem(
        amount: 999.0,
        merchant: 'Myntra Reversal',
        category: 'Shopping',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: reversalTx, existingTransactions: [debitTx]),
          isFalse);
    });

    // 11. CSV + SMS duplicate
    test('11. CSV + SMS duplicate detected via UTR reference', () {
      final csvTx = TransactionItem(
        amount: 3500.0,
        merchant: 'Amazon Shopping',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime(2026, 8, 10),
        transactionReference: 'UTR1122334455',
      );
      final smsTx = TransactionItem(
        amount: 3500.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 10),
        transactionReference: 'UTR1122334455',
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: smsTx, existingTransactions: [csvTx]),
          isTrue);
    });

    // 12. Manual + SMS duplicate
    test(
        '12. Manual + SMS possible duplicate detected via reference or composite match',
        () {
      final manualTx = TransactionItem(
        amount: 650.0,
        merchant: 'Blinkit',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        transactionReference: 'UPI00998877',
      );
      final smsTx = TransactionItem(
        amount: 650.0,
        merchant: 'Blinkit',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'UPI00998877',
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: smsTx, existingTransactions: [manualTx]),
          isTrue);
    });

    // 13. Repeated batch import
    test(
        '13. Repeated batch import correctly flags duplicate items in subsequent batch',
        () {
      final batchItem1 = TransactionItem(
        amount: 1500.0,
        merchant: 'Airtel Bill',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'REF_BATCH_100',
      );
      final batchItem2 = TransactionItem(
        amount: 1500.0,
        merchant: 'Airtel Bill',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'REF_BATCH_100',
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: batchItem2, existingTransactions: [batchItem1]),
          isTrue);
    });

    // 14. Split transaction duplicate checking
    test('14. Split transaction parent duplicate check works cleanly', () {
      final splitTx = TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        splits: [
          TransactionSplit(category: 'Food', amount: 600.0),
          TransactionSplit(category: 'Home', amount: 400.0),
        ],
        transactionReference: 'REF_SPLIT_001',
      );
      final candidateTx = TransactionItem(
        amount: 1000.0,
        merchant: 'Supermarket',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: 'REF_SPLIT_001',
      );
      expect(
          DuplicateHashDetector.isDuplicate(
              candidate: candidateTx, existingTransactions: [splitTx]),
          isTrue);
    });
  });
}
