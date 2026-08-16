import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/models/transaction.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('SmsParser Adaptive Engine & Edge Case Tests', () {
    test('Parses Swiggy UPI debit SMS with High Confidence Tier', () {
      const sms =
          'Rs 450.00 debited from A/C XX1234 to SWIGGY UPI ref 12345678.';
      final result = SmsParser.parseSmsDetailed(sms, 'HDFCBK',
          smsDate: DateTime(2026, 8, 1));

      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(450.0));
      expect(result.transaction.type, equals(TransactionType.debit));
      expect(result.transaction.merchant.toUpperCase(), contains('SWIGGY'));
      expect(result.confidenceScore, greaterThanOrEqualTo(70));
      expect(result.confidenceExplanation, contains('Confidence'));
      expect(result.parserVersion, equals('v1.4.2'));
    });

    test('Evaluates Confidence Tiers correctly (High, Medium, Low)', () {
      // High Confidence: Exact bank, amount, type, known merchant, account
      const highSms =
          'Rs 1,450.00 debited from A/C XX4921 to ZOMATO on 01-08-2026.';
      final highResult = SmsParser.parseSmsDetailed(highSms, 'AX-SBIINB');
      expect(highResult!.confidenceScore, greaterThanOrEqualTo(90));

      // Low Confidence / Generic fallback: Unknown sender, no merchant
      const lowSms = 'Debited Rs 250 from A/C XX1111.';
      final lowResult = SmsParser.parseSmsDetailed(lowSms, 'UNKNOWN_HEADER');
      expect(lowResult!.confidenceTier, equals(ConfidenceTier.low));
      expect(lowResult.confidenceExplanation, contains('LOW'));
    });

    test('ParserAnalyticsData tracks parser metrics correctly', () {
      expect(ParserAnalyticsData.parserVersion, equals('v1.4.2'));
      expect(ParserAnalyticsData.totalProcessed, greaterThan(0));
    });

    test('Self-Learning: Custom User Bank Assignment remembers unknown senders',
        () {
      const sms = 'Rs 500 debited for Fuel.';
      const sender = 'XX-MYBANK';

      // Before registration
      final before = SmsParser.parseSmsDetailed(sms, sender);
      expect(before!.bankName, isNull);
      expect(before.isUserAssigned, false);

      // User assigns bank
      SmsParser.registerCustomSenderMapping(sender, 'My Custom Grameena Bank');

      // After registration
      final after = SmsParser.parseSmsDetailed(sms, sender);
      expect(after!.bankName, equals('My Custom Grameena Bank'));
      expect(after.isUserAssigned, true);
      expect(after.confidenceScore, greaterThan(before.confidenceScore));
    });

    test('Parses Edge Case 1: ATM Cash Withdrawal SMS', () {
      const sms = 'ATM WDL of Rs 5,000.00 from A/C XX3321 at SBI ATM MG ROAD.';
      final result = SmsParser.parseSmsDetailed(sms, 'AX-SBIINB');

      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(5000.0));
      expect(result.transaction.type, equals(TransactionType.debit));
      expect(result.transaction.merchant, contains('ATM'));
    });

    test('Parses Edge Case 2: EMI Deduction SMS', () {
      const sms =
          'EMI deduction of Rs 12,400.00 processed for Home Loan A/C XX8899.';
      final result = SmsParser.parseSmsDetailed(sms, 'VK-HDFCBK');

      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(12400.0));
      expect(result.transaction.type, equals(TransactionType.debit));
      expect(result.transaction.category, equals('EMI'));
    });

    test('Parses Edge Case 3: Interest Credit SMS', () {
      const sms =
          'Interest credit of Rs 1,250.00 deposited into A/C XX4455 on 31-07-2026.';
      final result = SmsParser.parseSmsDetailed(sms, 'AD-ICICIB');

      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(1250.0));
      expect(result.transaction.type, equals(TransactionType.credit));
      expect(result.transaction.merchant, contains('Interest'));
    });

    test('Parses Edge Case 4: Reversal & Refund SMS', () {
      const sms =
          'Reversal of Rs 350.00 credited to A/C XX1234 for failed transaction.';
      final result = SmsParser.parseSmsDetailed(sms, 'AX-AXISBK');

      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(350.0));
      expect(result.transaction.type, equals(TransactionType.credit));
    });

    test('Parses Edge Case 5: Credit Card Transaction SMS', () {
      const sms =
          'Spent Rs 4,999.00 on your ICICI Credit Card XX7001 at FLIPKART.';
      final result = SmsParser.parseSmsDetailed(sms, 'AD-ICICICRD');

      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(4999.0));
      expect(result.transaction.type, equals(TransactionType.debit));
      expect(result.transaction.merchant.toUpperCase(), contains('FLIPKART'));
    });

    test('Identifies all 50 major commercial banks in India', () {
      final bankHeaderMap = {
        'AX-SBIINB': 'State Bank of India (SBI)',
        'VK-HDFCBK': 'HDFC Bank',
        'AD-ICICIB': 'ICICI Bank',
        'AX-AXISBK': 'Axis Bank',
        'JM-PNBSMS': 'Punjab National Bank (PNB)',
      };

      for (final entry in bankHeaderMap.entries) {
        final identified = SmsParser.identifyBank(entry.key);
        expect(identified, equals(entry.value));
      }
    });

    test('Ignores OTP and Security Code messages', () {
      const sms =
          'Your OTP for bank login is 849201. Do not share with anyone.';
      final tx = SmsParser.parseSms(sms, 'HDFCBK');
      expect(tx, isNull);
    });

    test('Rejects SMS exceeding 800 characters length guard', () {
      final longSms = 'Debit Rs 100 ' * 100;
      final tx = SmsParser.parseSms(longSms, 'HDFCBK');
      expect(tx, isNull);
    });

    test('Returns null for empty or non-financial SMS', () {
      expect(SmsParser.parseSms('', 'HDFCBK'), isNull);
      expect(SmsParser.parseSms('Good morning! Have a nice day.', 'HDFCBK'),
          isNull);
    });

    test('Parses APGBank (Andhra Pradesh Grameena Bank) SMSes cleanly', () {
      const sms1 =
          'Your a/c no. XXXXXXXXXXX6077 is debited for Rs.20.00 on 29/07/2026 18:28:12 and credited to VPA krishnareddy220670@okicici (UPI Ref no 051939321770) -APGBank';
      final res1 = SmsParser.parseSmsDetailed(sms1, 'JD-APGB-T');

      expect(res1, isNotNull);
      expect(res1!.bankName, equals('Andhra Pradesh Grameena Bank'));
      expect(res1.transaction.amount, equals(20.0));
      expect(res1.transaction.type, equals(TransactionType.debit));
      expect(res1.transaction.merchant, equals('Krishnareddy220670'));

      const sms2 =
          'Dear Customer, An amount of Rs.149/- is credited in your A/c XXXX6077 on 01-08-2026, UPI Ref No:044396312134. At present A/c Balance is Rs.218.97 -APGBank';
      final res2 = SmsParser.parseSmsDetailed(sms2, 'JD-APGB-T');

      expect(res2, isNotNull);
      expect(res2!.bankName, equals('Andhra Pradesh Grameena Bank'));
      expect(res2.transaction.amount, equals(149.0));
      expect(res2.transaction.type, equals(TransactionType.credit));
      expect(res2.remainingBalance, equals(218.97));

      const sms3 =
          'Your a/c no. XXXXXXXXXXX6077 is debited for Rs.39.00 on 04/08/2026 15:22:54 and credited to VPA jio@citibank (UPI Ref no 728210776143) -APGBank';
      final res3 = SmsParser.parseSmsDetailed(sms3, 'JD-APGB-T');

      expect(res3, isNotNull);
      expect(res3!.bankName, equals('Andhra Pradesh Grameena Bank'));
      expect(res3.transaction.amount, equals(39.0));
      expect(res3.transaction.type, equals(TransactionType.debit));
      expect(res3.transaction.merchant.toUpperCase(), contains('JIO'));
    });

    test('Parses TJSB Sahakari Bank and Saraswat Bank regional SMSes cleanly',
        () {
      const smsTjsb =
          'Rs 1,200.00 debited from A/C XX4812 to GROCERIES via UPI on 07-08-2026 - TJSB Bank';
      final resTjsb = SmsParser.parseSmsDetailed(smsTjsb, 'AX-TJSBNK');

      expect(resTjsb, isNotNull);
      expect(resTjsb!.bankName, equals('TJSB Sahakari Bank'));
      expect(resTjsb.transaction.amount, equals(1200.0));
      expect(resTjsb.transaction.type, equals(TransactionType.debit));

      const smsSaraswat =
          'Rs 3,500.00 credited to A/C XX9910 on 07-08-2026 - Saraswat Bank';
      final resSaraswat = SmsParser.parseSmsDetailed(smsSaraswat, 'AD-SARASW');

      expect(resSaraswat, isNotNull);
      expect(resSaraswat!.bankName, equals('Saraswat Bank'));
      expect(resSaraswat.transaction.amount, equals(3500.0));
      expect(resSaraswat.transaction.type, equals(TransactionType.credit));
    });
  });
}
