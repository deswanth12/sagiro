import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/models/transaction.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Problem 5: SMS Scanner Accuracy Test Suite', () {
    test(
        '1. Disambiguates multiple amounts (Transaction amount vs. Account balance)',
        () {
      const sms =
          'Your A/C XX1234 Avail Bal is Rs. 45,230.50. Rs. 750.00 debited for Swiggy on 13-08-2026.';
      final res = SmsParser.parseSmsDetailed(sms, 'AX-HDFCBK');

      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(750.0));
      expect(res.remainingBalance, equals(45230.50));
      expect(res.transaction.type, equals(TransactionType.debit));
    });

    test(
        '2. Handles different amount formats (commas, decimals, symbols, casing)',
        () {
      const cases = [
        {'sms': 'Spent ₹1,234.56 at ZOMATO', 'amount': 1234.56},
        {'sms': 'Rs. 1,234 debited for Petrol', 'amount': 1234.0},
        {'sms': 'INR 1234 credited to A/C XX1111', 'amount': 1234.0},
        {'sms': 'amount of Rs.500.50 debited', 'amount': 500.50},
      ];

      for (final c in cases) {
        final res = SmsParser.parseSmsDetailed(c['sms'] as String, 'AX-SBIINB');
        expect(res, isNotNull, reason: 'Failed for ${c["sms"]}');
        expect(res!.transaction.amount, equals(c['amount']),
            reason: 'Amount mismatch for ${c["sms"]}');
      }
    });

    test('3. Rejects OTPs, Passwords, and Security Codes (0 False Positives)',
        () {
      const otps = [
        'Your OTP for netbanking login is 948201. Do not share it with anyone.',
        'Verification code 123456 for card transaction.',
        'Secret code to authorize Rs 500 transaction is 8821.',
      ];

      for (final sms in otps) {
        final res = SmsParser.parseSmsDetailed(sms, 'AX-HDFCBK');
        expect(res, isNull, reason: 'OTP should be rejected: $sms');
      }
    });

    test('4. Rejects Failed, Declined, or Unsuccessful Transactions', () {
      const failedSms = [
        'Txn of Rs. 500.00 FAILED at Swiggy due to insufficient balance.',
        'Transaction of Rs. 1,200.00 DECLINED on your ICICI credit card.',
        'Payment of Rs 250 could not be processed.',
      ];

      for (final sms in failedSms) {
        final res = SmsParser.parseSmsDetailed(sms, 'AX-ICICIB');
        expect(res, isNull,
            reason: 'Failed transaction should be rejected: $sms');
      }
    });

    test('5. Rejects Marketing, Promotional, and Pre-Approved Loan Offers', () {
      const promoSms = [
        'Get pre-approved personal loan up to Rs. 5,00,000 instantly. Apply now!',
        'Congratulations! You are eligible for instant loan of Rs 100,000. Click to apply.',
      ];

      for (final sms in promoSms) {
        final res = SmsParser.parseSmsDetailed(sms, 'AD-LOAN');
        expect(res, isNull, reason: 'Promotional SMS should be rejected: $sms');
      }
    });

    test('6. Correctly parses Refunds and Reversals as Credit', () {
      const sms =
          'Refund of Rs. 450.00 credited to A/C XX4321 for returned item. Ref UTR987654321.';
      final res = SmsParser.parseSmsDetailed(sms, 'AX-AXISBK');

      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(450.0));
      expect(res.transaction.type, equals(TransactionType.credit));
      expect(res.transaction.transactionReference, equals('UTR987654321'));
    });

    test('7. Correctly parses Salary Credits', () {
      const sms =
          'Salary credited Rs. 85,000.00 in A/C XX9001 on 31-07-2026. Avail Bal Rs 1,12,000.00.';
      final res = SmsParser.parseSmsDetailed(sms, 'AX-HDFCBK');

      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(85000.0));
      expect(res.transaction.type, equals(TransactionType.credit));
      expect(res.transaction.merchant, contains('Salary'));
      expect(res.remainingBalance, equals(112000.0));
    });

    test('8. Correctly extracts VPA and UPI references', () {
      const sms =
          'Rs 20.00 debited from A/C XX6077 and credited to VPA testuser@okicici (UPI Ref no 051939321770).';
      final res = SmsParser.parseSmsDetailed(sms, 'JD-APGB-T');

      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(20.0));
      expect(res.transaction.merchant, equals('Testuser'));
      expect(res.transaction.transactionReference, equals('051939321770'));
    });

    test('9. Privacy Check: rawSms is always NULL in parsed result', () {
      const sms = 'Rs 500 debited from A/C XX1234 at Swiggy.';
      final res = SmsParser.parseSmsDetailed(sms, 'AX-HDFCBK');

      expect(res, isNotNull);
      expect(res!.transaction.rawSms, isNull);
    });
  });
}
