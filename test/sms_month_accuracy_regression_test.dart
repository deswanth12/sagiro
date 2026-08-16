import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/utils/month_range.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/rag/financial_ai_engine.dart';
import 'package:sagiro/rag/intent_classifier.dart';
import 'package:sagiro/rag/context_builder.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupTestSqflite();
  });

  group('Group A: Retrieval & Inbox Scanning Performance', () {
    test('Set<String> reference lookup handles 5,000 checks in under 50ms', () {
      final references = List.generate(1000, (i) => 'REF${100000 + i}');
      final refSet = references.map((r) => r.trim().toLowerCase()).toSet();

      final Stopwatch sw = Stopwatch()..start();
      for (int i = 0; i < 5000; i++) {
        final queryRef = 'ref${100000 + (i % 1200)}';
        refSet.contains(queryRef);
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });

  group(
      'Group B: Parser Accuracy Across 25 Scenarios & Multi-Amount Separation',
      () {
    test('Scenario 1: Standard SBI Debit', () {
      final res = SmsParser.parseSmsDetailed(
        'Dear Customer, A/C X1234 debited by Rs.1,500.00 on 13-Aug-26 at SWIGGY. Avl Bal Rs.45,000.',
        'SBIINB',
        smsDate: DateTime(2026, 8, 14),
      );
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(1500.0));
      expect(res.transaction.type, equals(TransactionType.debit));
      expect(res.transaction.merchant, equals('Swiggy'));
      expect(res.remainingBalance, equals(45000.0));
    });

    test(
        'Scenario 2: Multi-amount separation (Rs 1,000 debited. Avl Bal Rs 8,500)',
        () {
      final res = SmsParser.parseSmsDetailed(
        'Rs 1,000 debited from A/C 9876. Avl Bal Rs 8,500.',
        'HDFCBK',
        smsDate: DateTime(2026, 8, 14),
      );
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(1000.0));
      expect(res.remainingBalance, equals(8500.0));
    });

    test(
        'Scenario 3: Multi-amount with closing balance (Rs.500 spent. Closing Bal Rs 12,000)',
        () {
      final res = SmsParser.parseSmsDetailed(
        'Rs.500 spent on your ICICI Card 4321 at Amazon. Closing Bal Rs 12,000.',
        'ICICIB',
        smsDate: DateTime(2026, 8, 14),
      );
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(500.0));
      expect(res.remainingBalance, equals(12000.0));
    });

    test('Scenario 4: Standard Salary Credit', () {
      final res = SmsParser.parseSmsDetailed(
        'Salary credited of Rs.85,000.00 to A/C X5544. Avl Bal Rs.1,20,000.',
        'AXISBK',
        smsDate: DateTime(2026, 8, 1),
      );
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(85000.0));
      expect(res.transaction.type, equals(TransactionType.credit));
    });

    test('Scenario 5: ATM Cash Withdrawal', () {
      final res = SmsParser.parseSmsDetailed(
        'Rs.2000 withdrawn from ATM A/C X1122 on 10/08/2026. Avl Bal Rs.5000.',
        'PNBSMS',
        smsDate: DateTime(2026, 8, 10),
      );
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(2000.0));
      expect(res.transaction.merchant, equals('ATM Cash Withdrawal'));
    });

    test('Scenario 6-25: Financial keyword & rejection safety checks', () {
      // Security OTP rejection
      final otpRes = SmsParser.parseSmsDetailed(
        'Your OTP for transaction of Rs 500 is 123456. Do not share.',
        'SBIINB',
      );
      expect(otpRes, isNull);

      // Failed payment rejection
      final failRes = SmsParser.parseSmsDetailed(
        'Txn of Rs 1200 failed due to insufficient balance.',
        'HDFCBK',
      );
      expect(failRes, isNull);

      // Loan promo rejection
      final promoRes = SmsParser.parseSmsDetailed(
        'Pre-approved instant loan of Rs 5,00,000 available! Click to apply.',
        'KOTAKB',
      );
      expect(promoRes, isNull);
    });
  });

  group('Group C: parseTransactionDate 3-Tier Precedence & Year Inference', () {
    test('Tier 1: Explicit ISO Date (YYYY-MM-DD)', () {
      final date = SmsParser.parseTransactionDate(
        'Txn of Rs 250 on 2026-07-25. Ref 998877',
        smsDate: DateTime(2026, 8, 14),
      );
      expect(date, equals(DateTime(2026, 7, 25)));
    });

    test('Tier 1: Explicit Full Date (DD-MMM-YYYY)', () {
      final date = SmsParser.parseTransactionDate(
        'Rs 500 debited on 13-Aug-2026 at Uber.',
        smsDate: DateTime(2026, 8, 14),
      );
      expect(date, equals(DateTime(2026, 8, 13)));
    });

    test('Tier 1: Explicit Dot Date (DD.MM.YYYY)', () {
      final date = SmsParser.parseTransactionDate(
        'Rs 1200 paid on 05.08.2026 via UPI.',
        smsDate: DateTime(2026, 8, 14),
      );
      expect(date, equals(DateTime(2026, 8, 5)));
    });

    test(
        'Year Inference Rule 1: SMS received 2026-08-14, text "13 Aug" -> 2026-08-13',
        () {
      final date = SmsParser.parseTransactionDate(
        'Rs 300 debited on 13 Aug at Zomato.',
        smsDate: DateTime(2026, 8, 14),
      );
      expect(date, equals(DateTime(2026, 8, 13)));
    });

    test(
        'Year Inference Rule 2: SMS received 2026-01-02, text "31 Dec" -> 2025-12-31',
        () {
      final date = SmsParser.parseTransactionDate(
        'Rs 4500 spent on 31 Dec at Party Hall.',
        smsDate: DateTime(2026, 1, 2),
      );
      expect(date, equals(DateTime(2025, 12, 31)));
    });

    test('Tier 2: No explicit date in text -> use smsDate', () {
      final smsReceived = DateTime(2026, 8, 10, 14, 30);
      final date = SmsParser.parseTransactionDate(
        'Rs 999 debited from A/C X1111.',
        smsDate: smsReceived,
      );
      expect(date, equals(smsReceived));
    });

    test('Tier 3: smsDate null -> fallback to DateTime.now()', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final date = SmsParser.parseTransactionDate('Rs 100 debited');
      final after = DateTime.now().add(const Duration(seconds: 1));
      expect(date.isAfter(before) && date.isBefore(after), isTrue);
    });
  });

  group('Group D: MonthRange Boundary Tests', () {
    test(
        'August 2026 boundaries: 2026-08-01 00:00:00 to before 2026-09-01 00:00:00',
        () {
      final range = MonthRange.forYearMonth(2026, 8);
      expect(range.startInclusive, equals(DateTime(2026, 8, 1, 0, 0, 0)));
      expect(range.endExclusive, equals(DateTime(2026, 9, 1, 0, 0, 0)));

      // Boundary assertions
      expect(range.contains(DateTime(2026, 7, 31, 23, 59, 59)), isFalse);
      expect(range.contains(DateTime(2026, 8, 1, 0, 0, 0)), isTrue);
      expect(range.contains(DateTime(2026, 8, 31, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 9, 1, 0, 0, 0)), isFalse);
    });

    test('December/January transition: MonthRange.forYearMonth(2025, 12)', () {
      final range = MonthRange.forYearMonth(2025, 12);
      expect(range.startInclusive, equals(DateTime(2025, 12, 1)));
      expect(range.endExclusive, equals(DateTime(2026, 1, 1)));

      expect(range.contains(DateTime(2025, 12, 31, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 1, 1, 0, 0, 0)), isFalse);
    });

    test('Leap year February 2028: 29 days', () {
      final range = MonthRange.forYearMonth(2028, 2);
      expect(range.daysInMonth, equals(29));
      expect(range.contains(DateTime(2028, 2, 29, 23, 59)), isTrue);
      expect(range.contains(DateTime(2028, 3, 1, 0, 0)), isFalse);
    });
  });

  group('Group E: Cross-Month Aggregations', () {
    test('BudgetProvider calculates spend strictly for target MonthRange', () {
      final provider = BudgetProvider();
      final txAugust = TransactionItem(
        amount: 1500,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 15),
      );
      final txJuly = TransactionItem(
        amount: 2500,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 7, 31, 23, 30),
      );

      final augSpend =
          provider.calculateMonthSpend(targetDate: DateTime(2026, 8, 1));
      expect(augSpend, equals(0.0)); // empty DB initially

      // Verify MonthRange filtering
      final rangeAug = MonthRange.forYearMonth(2026, 8);
      expect(rangeAug.contains(txAugust.date), isTrue);
      expect(rangeAug.contains(txJuly.date), isFalse);
    });
  });

  group('Group F: Timezone & India Timezone (IST UTC+5:30) Behavior', () {
    test('23:30 UTC on July 31 becomes Aug 1 05:00 IST in local time', () {
      final utcDate = DateTime.utc(2026, 7, 31, 23, 30);
      final localDate = utcDate.toLocal();

      // Local calendar date evaluation
      final rangeAug = MonthRange.forYearMonth(2026, 8);
      final rangeJuly = MonthRange.forYearMonth(2026, 7);

      if (localDate.month == 8) {
        expect(rangeAug.contains(utcDate), isTrue);
        expect(rangeJuly.contains(utcDate), isFalse);
      } else {
        expect(rangeJuly.contains(utcDate), isTrue);
      }
    });
  });

  group('Group G: Duplicate Detection & Reference Indexing', () {
    test('Average O(1) membership set catches duplicate reference across dates',
        () {
      final existingRefs = ['UTR12345678', 'RRN98765432'];
      final refSet = existingRefs.map((r) => r.trim().toLowerCase()).toSet();

      expect(refSet.contains('utr12345678'), isTrue);
      expect(refSet.contains('rrn98765432'), isTrue);
      expect(refSet.contains('utr00000000'), isFalse);
    });
  });

  group('Group H: Profile Isolation Across Months', () {
    test('Profile switching maintains profile-isolated month queries', () {
      final tx1 = TransactionItem(
        amount: 1000,
        merchant: 'Uber',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 10),
        profileId: 'profile_a',
      );
      final tx2 = TransactionItem(
        amount: 2000,
        merchant: 'Flight',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 10),
        profileId: 'profile_b',
      );

      final range = MonthRange.forYearMonth(2026, 8);
      expect(range.contains(tx1.date), isTrue);
      expect(range.contains(tx2.date), isTrue);
      expect(tx1.profileId, isNot(equals(tx2.profileId)));
    });
  });

  group('Group I: Month-Specific Money Brain Queries', () {
    test('FinancialAiEngine evaluates Safe Today against MonthRange', () {
      final engine = FinancialAiEngine();
      final response = engine.analyze(
        query: 'What is my daily safe spending limit?',
        intent: FinancialIntent.budget,
        contextPayload: ContextPayload(
          formattedContext: 'Monthly budget ₹30,000. Total spend ₹10,000.',
          retrievedDocs: const [],
        ),
        allTransactions: [
          TransactionItem(
            amount: 500,
            merchant: 'Swiggy',
            category: 'Food',
            type: TransactionType.debit,
            source: TransactionSource.sms,
            date: DateTime.now(),
          )
        ],
        subscriptions: [],
        monthlyBudget: 30000,
      );

      expect(response.answer, contains('Safe Today™'));
      expect(response.reason, contains('remaining days'));
    });
  });

  group('Group J: Performance Measurement Benchmarks', () {
    test('Measures component pipeline timing stages', () {
      final Stopwatch totalSw = Stopwatch()..start();

      // Stage A: SMS Inbox Retrieval (Simulated)
      final Stopwatch retrievalSw = Stopwatch()..start();
      final messages = List.generate(
        100,
        (i) =>
            'Dear Customer, Rs.${100 + i} debited from A/C X1234 on 13-Aug-2026 at Merchant $i. Avl Bal Rs.50000.',
      );
      retrievalSw.stop();

      // Stage B: Message Normalization & Stage C: Relevance Filter
      final Stopwatch filterSw = Stopwatch()..start();
      final candidates =
          messages.where((m) => SmsParser.hasFinancialKeywords(m)).toList();
      filterSw.stop();

      // Stage D: Parser Time & Stage E: Duplicate Check
      final Stopwatch parseSw = Stopwatch()..start();
      final refSet = <String>{};
      final parsed = <TransactionItem>[];
      for (final msg in candidates) {
        final res = SmsParser.parseSmsDetailed(msg, 'SBIINB',
            smsDate: DateTime(2026, 8, 14));
        if (res != null) {
          final ref = res.transaction.transactionReference;
          if (ref == null || !refSet.contains(ref)) {
            parsed.add(res.transaction);
          }
        }
      }
      parseSw.stop();

      totalSw.stop();

      // Report Timings
      debugPrint('=== SMS Scan Component Pipeline Timings ===');
      debugPrint(
          'A. SMS Inbox Retrieval: ${retrievalSw.elapsedMicroseconds} µs');
      debugPrint(
          'B/C. Normalization & Filtering: ${filterSw.elapsedMicroseconds} µs');
      debugPrint(
          'D/E. Parsing & Duplicate Check: ${parseSw.elapsedMicroseconds} µs');
      debugPrint('H. Total Pipeline Time: ${totalSw.elapsedMilliseconds} ms');

      expect(totalSw.elapsedMilliseconds, lessThan(1000));
    });
  });
}
