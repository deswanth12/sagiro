import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/sms_classifier.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/models/transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SAGIRO SMS Spam / Promotional / Non-Financial Filter Red-Team Tests',
      () {
    // ── 1. Real Debit SMS → ACCEPT ──────────────────────────────────────────
    test('1. Real debit SMS -> ACCEPT', () {
      const sender = 'AD-HDFCBK';
      const body =
          'Dear Customer, Rs. 1499.00 has been debited from your A/c XX4321 on 14-AUG-26 to SWIGGY. Avl Bal: Rs 45,210.50. Ref: 624819201948.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(1499.00));
      expect(parsed.transaction.type, equals(TransactionType.debit));
      expect(parsed.transaction.merchant, equals('Swiggy'));
    });

    // ── 2. Real Credit SMS → ACCEPT ──────────────────────────────────────────
    test('2. Real credit SMS -> ACCEPT', () {
      const sender = 'VM-SBIINB';
      const body =
          'Your A/c XX8910 is credited with INR 65,000.00 on 14-Aug-2026 by Salary Credited from ACME CORP. Ref UTR: 994820194820.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(65000.00));
      expect(parsed.transaction.type, equals(TransactionType.credit));
    });

    // ── 3. UPI Completed → ACCEPT ───────────────────────────────────────────
    test('3. UPI completed -> ACCEPT', () {
      const sender = 'AX-AXISBK';
      const body =
          'UPI/624819201948: Rs 379.00 debited from A/c XX1234 on 14-08-26 to googleone@okaxis (UPI Ref 624819201948).';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(379.00));
      expect(parsed.transaction.type, equals(TransactionType.debit));
    });

    // ── 4. ATM Withdrawal → ACCEPT ───────────────────────────────────────────
    test('4. ATM withdrawal -> ACCEPT', () {
      const sender = 'ICICIB';
      const body =
          'Dear Customer, cash withdrawal of Rs. 4,000.00 from ATM Indiranagar on Card XX9012 on 14-Aug-2026. Avl Bal: Rs 18,300.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(4000.00));
      expect(parsed.transaction.type, equals(TransactionType.debit));
      expect(parsed.transaction.merchant, contains('ATM'));
    });

    // ── 5. NEFT → ACCEPT ────────────────────────────────────────────────────
    test('5. NEFT -> ACCEPT', () {
      const sender = 'KOTAKB';
      const body =
          'NEFT transfer of Rs 12,500.00 debited from A/c XX5544 to Landlord Rent on 14-08-2026. Ref NEFT/KKBK12345678.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(12500.00));
      expect(parsed.transaction.type, equals(TransactionType.debit));
    });

    // ── 6. IMPS → ACCEPT ────────────────────────────────────────────────────
    test('6. IMPS -> ACCEPT', () {
      const sender = 'PNBSMS';
      const body =
          'IMPS transfer of INR 2,200.00 debited from your A/c XX9988 to Rohit Sharma. Ref: IMPS/62481920.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(2200.00));
      expect(parsed.transaction.type, equals(TransactionType.debit));
    });

    // ── 7. Refund → ACCEPT ──────────────────────────────────────────────────
    test('7. Refund -> ACCEPT', () {
      const sender = 'AD-HDFCBK';
      const body =
          'Rs 850.00 refunded to your HDFC Bank Card XX7711 on 14-Aug-2026 for returned order at Amazon Pay. Ref: REF850123.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(850.00));
      expect(parsed.transaction.type, equals(TransactionType.credit));
    });

    // ── 8. Reversal → ACCEPT ────────────────────────────────────────────────
    test('8. Reversal -> ACCEPT', () {
      const sender = 'BOBTXN';
      const body =
          'Reversal of Rs 500.00 credited to your A/c XX3322 on 14-Aug-2026 towards failed merchant transaction. Ref: REV500987.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(500.00));
      expect(parsed.transaction.type, equals(TransactionType.credit));
    });

    // ── 9. OTP with ₹ Amount → REJECT ───────────────────────────────────────
    test('9. OTP with ₹ amount -> REJECT', () {
      const sender = 'AD-HDFCBK';
      const body =
          '483921 is your secret OTP for payment of Rs 1,499.00 at Swiggy on Card XX4321. Valid for 5 mins. Do not share OTP with anyone.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isOtp, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 10. Bank Promotion → REJECT ─────────────────────────────────────────
    test('10. Bank promotion -> REJECT', () {
      const sender = 'AD-HDFCBK';
      const body =
          'Get a lifetime-free credit card with HDFC Bank! Enjoy 5% cashback on all online spends. Apply now at hdfcbk.io/apply';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 11. Airtel Promotion → REJECT ───────────────────────────────────────
    test('11. Airtel promotion -> REJECT', () {
      const sender = 'AD-AIRTEL';
      const body =
          'Recharge with Rs 299 and get unlimited calls & 2GB/day extra data. Special Airtel offer valid today only!';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 12. Cashback Advertisement → REJECT ─────────────────────────────────
    test('12. Cashback advertisement -> REJECT', () {
      const sender = 'PAYTMB';
      const body =
          'Special offer for you! Get 20% cashback up to ₹500 on your next grocery purchase with Paytm. Use coupon SAVE20.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 13. Amazon Delivery → REJECT ────────────────────────────────────────
    test('13. Amazon delivery -> REJECT', () {
      const sender = 'AMAZON';
      const body =
          'Your Amazon order has shipped and will arrive today by 8 PM. Track package: amzn.in/track/123';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isDelivery, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 14. Loan Advertisement → REJECT ─────────────────────────────────────
    test('14. Loan advertisement -> REJECT', () {
      const sender = 'BAJAJF';
      const body =
          'Congratulations! Pre-approved personal loan available up to Rs 5,00,000 at zero processing fee. Click to apply now.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 15. Credit Card Offer → REJECT ──────────────────────────────────────
    test('15. Credit card offer -> REJECT', () {
      const sender = 'ICICIB';
      const body =
          'Dear Customer, your credit limit is increased to Rs 2,50,000. Upgrade your ICICI Bank credit card today!';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 16. Reward Message → REJECT ─────────────────────────────────────────
    test('16. Reward message -> REJECT', () {
      const sender = 'CRED';
      const body =
          'You have earned 15,000 reward points on your recent activity! Redeem your cashback now on CRED.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 17. Personal SMS → REJECT ───────────────────────────────────────────
    test('17. Personal SMS -> REJECT', () {
      const sender = '+919876543210';
      const body =
          'Hey, are you free this evening? Call me back when you get a chance.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPersonal, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 18. Scam Message → REJECT ───────────────────────────────────────────
    test('18. Scam message -> REJECT', () {
      const sender = 'PRIZES';
      const body =
          'Congratulations! You won ₹50,000 cash prize in our lucky draw. Click this link immediately to claim your reward.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isSpam, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 19. "Win ₹50,000" → REJECT ──────────────────────────────────────────
    test('19. "Win ₹50,000" -> REJECT', () {
      const sender = 'LOTTO';
      const body =
          'Play now and win ₹50,000 today! Deposit Rs 100 to start playing.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isSpam || classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 20. "Get ₹500 cashback" → REJECT ────────────────────────────────────
    test('20. "Get ₹500 cashback" -> REJECT', () {
      const sender = 'AMAZON';
      const body =
          'Shop for ₹999 or more and get ₹500 cashback on Amazon Pay. Limited period offer.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 21. Bank Sender + Promotion → REJECT ────────────────────────────────
    test('21. Bank sender + promotion -> REJECT', () {
      const sender = 'AD-HDFCBK';
      const body =
          'Exclusive offer for HDFC Bank customers! Apply for a personal loan up to ₹10,00,000 at low interest.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 22. Bank Sender + Completed Debit → ACCEPT ──────────────────────────
    test('22. Bank sender + completed debit -> ACCEPT', () {
      const sender = 'AD-HDFCBK';
      const body =
          'Rs 379.00 debited from A/c XX4321 on 14-Aug-2026 via UPI to Google One. Ref: UPI123456789.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.merchant, equals('Google One'));
      expect(parsed.bankName, contains('HDFC'));
    });

    // ── 23. Airtel Sender + Recharge Completed → ACCEPT ─────────────────────
    test('23. Airtel sender + recharge completed -> ACCEPT', () {
      const sender = 'AD-AIRTEL';
      const body =
          'Recharge of Rs 299 is successful for your Airtel mobile 9876543210 on 14-Aug-2026. Transaction ID: AIRTEL883920.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isFinancial, isTrue);
      expect(classification.isCandidateForParsing, isTrue);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNotNull);
      expect(parsed!.transaction.amount, equals(299.00));
      expect(parsed.transaction.merchant, equals('Airtel Recharge'));
    });

    // ── 24. Airtel Sender + Recharge Offer → REJECT ─────────────────────────
    test('24. Airtel sender + recharge offer -> REJECT', () {
      const sender = 'AD-AIRTEL';
      const body =
          'Special Airtel offer: Recharge for Rs 299 and get extra data with unlimited calls. Click airtel.in/offer';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isPromotional, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 25. Security & KYC Alerts → REJECT ──────────────────────────────────
    test('25. Security & KYC alerts -> REJECT', () {
      const sender = 'SBIINB';
      const body =
          'New device login detected for your NetBanking account from Chrome on Windows at 14:30. If not you, call 18001234.';

      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isSecurityAlert, isTrue);
      expect(classification.isCandidateForParsing, isFalse);

      final parsed = SmsParser.parseSmsDetailed(body, sender);
      expect(parsed, isNull);
    });

    // ── 26. Precision, Recall, & F1 Score Red-Team Matrix ───────────────────
    test('26. Precision, Recall, & F1 Score Red-Team Evaluation (100% Target)',
        () {
      final groundTruth = <Map<String, dynamic>>[
        // Positive Financials (10 True Positives)
        {
          'body': 'Rs 100 debited from A/c XX1234 to Uber',
          'sender': 'HDFCBK',
          'isFinancial': true
        },
        {
          'body': 'INR 500.00 credited to A/c XX5678 by UPI transfer from John',
          'sender': 'SBIINB',
          'isFinancial': true
        },
        {
          'body': 'Cash withdrawal of Rs 2000 from ATM XX1122',
          'sender': 'ICICIB',
          'isFinancial': true
        },
        {
          'body': 'UPI payment of Rs 450 to Zomato successful. Ref: 123456',
          'sender': 'AXISBK',
          'isFinancial': true
        },
        {
          'body': 'Salary of INR 85000 credited to your A/c XX9900',
          'sender': 'KOTAKB',
          'isFinancial': true
        },
        {
          'body': 'NEFT transfer of Rs 5000 to Landlord debited. Ref: N12345',
          'sender': 'PNBSMS',
          'isFinancial': true
        },
        {
          'body': 'Rs 349 debited for Netflix subscription on Card XX4321',
          'sender': 'HDFCCRD',
          'isFinancial': true
        },
        {
          'body': 'Rs 1200 refunded to Card XX8877 from Flipkart',
          'sender': 'ICICICRD',
          'isFinancial': true
        },
        {
          'body': 'Reversal of Rs 300 credited to A/c XX2233',
          'sender': 'BOBTXN',
          'isFinancial': true
        },
        {
          'body': 'Recharge of Rs 299 is successful. Txn ID: AIRTEL123',
          'sender': 'AD-AIRTEL',
          'isFinancial': true
        },

        // Negative Non-Financials (14 True Negatives)
        {
          'body': 'Your OTP is 738291 for payment of Rs 100. Do not share.',
          'sender': 'HDFCBK',
          'isFinancial': false
        },
        {
          'body': 'Get 50% off up to Rs 200 on Swiggy with your HDFC card',
          'sender': 'HDFCBK',
          'isFinancial': false
        },
        {
          'body': 'Apply for instant loan up to Rs 500000 at 10.5% interest',
          'sender': 'BAJAJF',
          'isFinancial': false
        },
        {
          'body': 'Your Amazon package will arrive today by 5 PM',
          'sender': 'AMAZON',
          'isFinancial': false
        },
        {
          'body': 'Login detected on your SBI Netbanking account',
          'sender': 'SBIINB',
          'isFinancial': false
        },
        {
          'body': 'Recharge with Rs 299 and get extra data offer',
          'sender': 'AD-AIRTEL',
          'isFinancial': false
        },
        {
          'body':
              'Congratulations! You won ₹50,000 cash reward. Click to claim',
          'sender': 'WINNER',
          'isFinancial': false
        },
        {
          'body': 'Hey buddy, let me know when you reach home',
          'sender': '+919988776655',
          'isFinancial': false
        },
        {
          'body': 'Upgrade your credit card to get 10,000 bonus reward points',
          'sender': 'ICICIB',
          'isFinancial': false
        },
        {
          'body': 'Update your KYC to avoid account suspension',
          'sender': 'PNBBNK',
          'isFinancial': false
        },
        {
          'body': 'Get Rs 500 cashback on shopping of Rs 2000',
          'sender': 'PAYTM',
          'isFinancial': false
        },
        {
          'body': 'Win Rs 10000 every day by playing fantasy cricket',
          'sender': 'DREAM',
          'isFinancial': false
        },
        {
          'body':
              'Your Airtel bill payment is due tomorrow for Rs 599. Pay now to avoid fee.',
          'sender': 'AD-AIRTEL',
          'isFinancial': false
        },
        {
          'body':
              'Special offer: Pre-approved credit card with zero annual fees',
          'sender': 'AXISBK',
          'isFinancial': false
        },
      ];

      int tp = 0;
      int fp = 0;
      int tn = 0;
      int fn = 0;

      for (final item in groundTruth) {
        final body = item['body'] as String;
        final sender = item['sender'] as String;
        final expected = item['isFinancial'] as bool;

        final classification = SmsClassifier.classify(body, sender);
        final predicted = classification.isFinancial;

        if (predicted && expected) {
          tp++;
        } else if (predicted && !expected) {
          fp++;
          // Fail fast on false positive
          fail(
              'FALSE POSITIVE detected: Body="$body", Sender="$sender", Classification=${classification.classification}');
        } else if (!predicted && !expected) {
          tn++;
        } else if (!predicted && expected) {
          fn++;
          fail(
              'FALSE NEGATIVE detected: Body="$body", Sender="$sender", Classification=${classification.classification}');
        }
      }

      final precision = tp / (tp + fp);
      final recall = tp / (tp + fn);
      final f1 = 2 * (precision * recall) / (precision + recall);

      expect(fp, equals(0),
          reason: 'False Positives MUST BE ZERO for production safety');
      expect(fn, equals(0),
          reason: 'False Negatives MUST BE ZERO for key financial formats');
      expect(tn, equals(14));
      expect(precision, equals(1.0));
      expect(recall, equals(1.0));
      expect(f1, equals(1.0));
    });

    // ── 27. Large Scale Benchmark (1,000 and 10,000 SMS) ────────────────────
    test('27. High-Throughput Performance Benchmark (1,000 & 10,000 SMS)', () {
      const sampleBankSms =
          'Dear Customer, Rs. 379.00 has been debited from your A/c XX4321 on 14-AUG-26 to Google One. Ref: 624819201948.';
      const sampleOtpSms =
          '483921 is your secret OTP for payment of Rs 1,499.00 at Swiggy on Card XX4321. Valid for 5 mins.';
      const samplePromoSms =
          'Get a lifetime-free credit card with HDFC Bank! Enjoy 5% cashback on all online spends. Apply now.';

      final messages = <String>[
        sampleBankSms,
        sampleOtpSms,
        samplePromoSms,
      ];

      // Benchmark 1,000 SMS
      final sw1000 = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        final body = messages[i % 3];
        SmsClassifier.classify(body, 'AD-HDFCBK');
      }
      sw1000.stop();
      final time1000Ms = sw1000.elapsedMilliseconds;
      expect(time1000Ms, lessThan(200),
          reason: '1,000 classifications must complete in < 200ms');

      // Benchmark 10,000 SMS
      final sw10000 = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        final body = messages[i % 3];
        SmsClassifier.classify(body, 'AD-HDFCBK');
      }
      sw10000.stop();
      final time10000Ms = sw10000.elapsedMilliseconds;
      expect(time10000Ms, lessThan(1500),
          reason: '10,000 classifications must complete in < 1500ms');
    });
  });
}
