import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/services/merchant_intelligence_service.dart';
import 'package:sagiro/document_engine/duplicate/duplicate_hash_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  group('SAGIRO SMS Merchant Extraction & Deduplication Red-Team Suite', () {
    test('1. Explicit merchant in body (paid to SWIGGY)', () {
      const sms =
          'Rs 450.00 debited from A/c XX1234 on 13-08-2026 for UPI payment to SWIGGY. Ref: 123456789012. Avl Bal: Rs 14,200.00';
      final res = SmsParser.parseSmsDetailed(sms, 'HDFCBK');

      expect(res, isNotNull);
      expect(res!.transaction.merchant, equals('Swiggy'));
      expect(res.transaction.amount, equals(450.0));
      expect(res.transaction.type, equals(TransactionType.debit));
      expect(res.transaction.account, equals('XX1234'));
      expect(res.transaction.transactionReference, equals('123456789012'));
      expect(res.remainingBalance, equals(14200.0));
    });

    test('2. Subscription & Biller: Google One & Airtel Xstream Fiber', () {
      const smsGoogle =
          'Rs 379.00 debited from card XX9988 for Google One subscription on 10 Aug 2026. Avl Bal Rs 50,000';
      final resGoogle = SmsParser.parseSmsDetailed(smsGoogle, 'ICICIB');

      expect(resGoogle, isNotNull);
      expect(resGoogle!.transaction.merchant, equals('Google One'));
      expect(resGoogle.transaction.category, equals('Subscriptions'));
      expect(resGoogle.transaction.amount, equals(379.0));

      const smsAirtel =
          'Rs 349.00 debited towards Airtel Xstream Fiber bill payment. Ref 99881122.';
      final resAirtel = SmsParser.parseSmsDetailed(smsAirtel, 'AX-AIRTEL');

      expect(resAirtel, isNotNull);
      expect(resAirtel!.transaction.merchant, equals('Airtel Xstream Fiber'));
      expect(resAirtel.transaction.category, equals('Bills'));
      expect(resAirtel.transaction.amount, equals(349.0));
    });

    test('3. ATM cash withdrawal with location preservation', () {
      const smsAtm =
          'Cash withdrawal of Rs 5,000 at ATM TIRUPATI on 12/08/2026. Avl Bal Rs 8,500';
      final resAtm = SmsParser.parseSmsDetailed(smsAtm, 'SBIINB');

      expect(resAtm, isNotNull);
      expect(resAtm!.transaction.merchant, equals('ATM Tirupati'));
      expect(resAtm.transaction.amount, equals(5000.0));
      expect(resAtm.transaction.type, equals(TransactionType.debit));
      expect(resAtm.transaction.category, equals('Cash'));
    });

    test('4. POS merchant on card at RELIANCE RETAIL', () {
      const smsPos =
          'Rs 1,250 spent on card at RELIANCE RETAIL on 11-08-2026. Ref: POS88219';
      final resPos = SmsParser.parseSmsDetailed(smsPos, 'HDFCBK');

      expect(resPos, isNotNull);
      expect(resPos!.transaction.merchant, equals('Reliance Retail'));
      expect(resPos.transaction.amount, equals(1250.0));
    });

    test('5. UPI VPA extraction & normalization (abc@okaxis -> Abc)', () {
      const smsVpa =
          'Rs 500 debited from A/c XX4321 on 10/08/2026 transferred to rahul@okaxis UPI Ref: 987654321012';
      final resVpa = SmsParser.parseSmsDetailed(smsVpa, 'AXISBK');

      expect(resVpa, isNotNull);
      expect(resVpa!.transaction.merchant, equals('Rahul'));
      expect(resVpa.transaction.amount, equals(500.0));
      expect(resVpa.transaction.transactionReference, equals('987654321012'));
    });

    test('6. Legal suffix stripping: SWIGGY INDIA PVT LTD -> Swiggy', () {
      final normalized =
          MerchantIntelligenceService.normalizeMerchant('SWIGGY INDIA PVT LTD');
      expect(normalized, equals('Swiggy'));

      final normalizedZomato =
          MerchantIntelligenceService.normalizeMerchant('ZOMATO LIMITED');
      expect(normalizedZomato, equals('Zomato'));
    });

    test('7. Amount vs Balance separation', () {
      const sms = 'Rs 1,000 debited. Avl Bal Rs 8,500';
      final res = SmsParser.parseSmsDetailed(sms, 'HDFCBK');

      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(1000.0));
      expect(res.remainingBalance, equals(8500.0));
    });

    test('8. Duplicate Prevention: same SMS scanned twice -> duplicate flagged',
        () {
      final tx1 = TransactionItem(
        amount: 349.0,
        merchant: 'Airtel Xstream Fiber',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 20, 5),
        transactionReference: 'REF349001',
      );

      final isDup = DuplicateHashDetector.isDuplicate(
        candidate: tx1,
        existingTransactions: [tx1],
      );

      expect(isDup, isTrue);
    });

    test('9. Different UTRs on same day & amount -> NOT duplicate', () {
      final tx1 = TransactionItem(
        amount: 349.0,
        merchant: 'Airtel Xstream Fiber',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 20, 5),
        transactionReference: 'REF349001',
      );

      final tx2 = TransactionItem(
        amount: 349.0,
        merchant: 'Airtel Xstream Fiber',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 20, 5),
        transactionReference: 'REF349002',
      );

      final isDup = DuplicateHashDetector.isDuplicate(
        candidate: tx2,
        existingTransactions: [tx1],
      );

      expect(isDup, isFalse);
    });

    test('10. Different times without UTR (>15 min) -> NOT duplicate', () {
      final tx1 = TransactionItem(
        amount: 349.0,
        merchant: 'Airtel Xstream Fiber',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0),
      );

      final tx2 = TransactionItem(
        amount: 349.0,
        merchant: 'Airtel Xstream Fiber',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 20, 5),
      );

      final isDup = DuplicateHashDetector.isDuplicate(
        candidate: tx2,
        existingTransactions: [tx1],
      );

      expect(isDup, isFalse);
    });
  });
}
