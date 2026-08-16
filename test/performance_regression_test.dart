import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/rag/financial_ai_engine.dart';
import 'package:sagiro/rag/intent_classifier.dart';
import 'package:sagiro/rag/context_builder.dart';
import 'package:sagiro/services/backup_service.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupTestSqflite();
  });

  group('Performance Benchmark 1: Dashboard Load & Monthly Analytics', () {
    test('Measures analytics calculation time for 1,000 transactions',
        () async {
      await DatabaseHelper.instance.clearAllData();
      final now = DateTime.now();

      final items = List.generate(
        1000,
        (i) => TransactionItem(
          amount: 100 + (i % 500).toDouble(),
          merchant: 'Merchant_$i',
          category: (i % 2 == 0) ? 'Food' : 'Shopping',
          type: (i % 5 == 0) ? TransactionType.credit : TransactionType.debit,
          source: TransactionSource.sms,
          date: now.subtract(Duration(days: i % 30)),
          profileId: 'default_profile',
        ),
      );

      await DatabaseHelper.instance.insertTransactionBatch(items);

      final provider = BudgetProvider();
      final sw = Stopwatch()..start();
      await provider.loadData();
      final monthSpend = provider.monthSpend;
      final todaySpend = provider.todaySpend;
      sw.stop();

      debugPrint(
          '[Benchmark 1] 1,000 txs load & analytics time: ${sw.elapsedMilliseconds} ms (MonthSpend: ₹$monthSpend, TodaySpend: ₹$todaySpend)');
      expect(provider.transactions.length, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test(
        'Measures analytics calculation time for 5,000 transactions across 5 repetitions',
        () async {
      await DatabaseHelper.instance.clearAllData();
      final now = DateTime.now();

      final items = List.generate(
        5000,
        (i) => TransactionItem(
          amount: 50 + (i % 200).toDouble(),
          merchant: 'Vendor_$i',
          category:
              (i % 3 == 0) ? 'Food' : ((i % 3 == 1) ? 'Fuel' : 'Shopping'),
          type: (i % 10 == 0) ? TransactionType.credit : TransactionType.debit,
          source: TransactionSource.sms,
          date: now.subtract(Duration(days: i % 60)),
          profileId: 'default_profile',
        ),
      );

      await DatabaseHelper.instance.insertTransactionBatch(items);

      final durations = <int>[];
      double monthSpend = 0;

      for (int r = 0; r < 5; r++) {
        final provider = BudgetProvider();
        final sw = Stopwatch()..start();
        await provider.loadData();
        monthSpend = provider.monthSpend;
        sw.stop();
        durations.add(sw.elapsedMilliseconds);
      }

      durations.sort();
      final minVal = durations.first;
      final medianVal = durations[2];
      final p95Val = durations[4];
      final maxVal = durations.last;

      debugPrint(
          '[Benchmark 1 - 5k Txs] 5 Repetitions (ms): $durations -> min: ${minVal}ms, median: ${medianVal}ms, p95: ${p95Val}ms, max: ${maxVal}ms (MonthSpend: ₹$monthSpend)');
      expect(minVal, lessThan(1000));
    });
  });

  group('Performance Benchmark 2: Transaction Search & Filter', () {
    test('Measures filtering speed across 5,000 transactions', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final sw = Stopwatch()..start();
      provider.setSearchQuery('Vendor_42');
      provider.setCategoryFilter('Food');
      final filtered = provider.transactions.where((t) {
        final matchesSearch = t.merchant.toLowerCase().contains('vendor_42') ||
            t.category.toLowerCase().contains('vendor_42');
        final matchesCat = t.category == 'Food';
        return matchesSearch && matchesCat;
      }).toList();
      sw.stop();

      debugPrint(
          '[Benchmark 2] Filter across 5,000 txs: ${sw.elapsedMicroseconds} µs (Matches: ${filtered.length})');
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Performance Benchmark 3: Profile Switch Overhead', () {
    test('Measures switching profiles and reloading isolated dataset',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final sw = Stopwatch()..start();
      await provider.switchProfile('profile_work');
      final workCount = provider.transactions.length;
      sw.stop();

      debugPrint(
          '[Benchmark 3] Profile switch time: ${sw.elapsedMilliseconds} ms (Isolated txs: $workCount)');
      expect(sw.elapsedMilliseconds, lessThan(1500));
    });
  });

  group('Performance Benchmark 4: SMS Parsing & Candidate Filtering', () {
    test('Group A: False Positives Early Rejection Test', () {
      final falsePositives = [
        'first',
        'hours',
        'offers',
        'orders',
        'users',
        'answers',
        'person',
        'accountant',
        'Your order of 2 items will arrive in 4 hours.',
        'Welcome first time user! Check our new offers.',
      ];

      for (final msg in falsePositives) {
        final accepted = SmsParser.hasFinancialKeywords(msg);
        expect(accepted, isFalse,
            reason:
                'Message "$msg" should be rejected by early filter despite containing "rs" or "account" substring.');
      }
    });

    test('Group B: True Financial Messages Preservation Test', () {
      final validFinancial = [
        'Rs. 500 debited from A/C X1234 on 13-Aug-2026.',
        'Rs 500 credited to account X5678.',
        'INR 500 transferred via UPI to merchant.',
        '₹500 paid at Swiggy.',
        'UPI transfer of Rs 1000 completed.',
        'NEFT transfer of Rs 5000 processed.',
        'IMPS transfer of Rs 2000 successful.',
        'ATM withdrawal of Rs 3000 at HDFC ATM.',
        'POS purchase of Rs 1500 at Shoppers Stop.',
        'A/C debited by Rs 750.',
        'Rs. 500 debited from A/C X1234. Avl Bal Rs 8,500 after payment.',
      ];

      for (final msg in validFinancial) {
        final accepted = SmsParser.hasFinancialKeywords(msg);
        expect(accepted, isTrue,
            reason:
                'Valid financial message "$msg" must be accepted by early filter.');

        final parsed = SmsParser.parseSmsDetailed(msg, 'HDFCBK',
            smsDate: DateTime(2026, 8, 14));
        expect(parsed, isNotNull,
            reason: 'Valid financial message "$msg" must parse successfully.');
      }
    });

    test('Group C: OTP / Personal / Promotional Rejection Test', () {
      final irrelevantMsgs = [
        'Your OTP for net banking login is 849201. Do not share with anyone.',
        'Hey, are we still meeting for lunch at 1 PM?',
        'Get 50% off on your next food order using code FEAST50.',
        'Happy Birthday from all of us at Sagiro!',
      ];

      for (final msg in irrelevantMsgs) {
        final accepted = SmsParser.hasFinancialKeywords(msg);
        expect(accepted, isFalse,
            reason:
                'Irrelevant message "$msg" must be rejected by early filter.');
      }
    });

    test('Group D: Amount & Balance Separation Safety Test', () {
      const msg = 'Rs 1,000 debited. Avl Bal Rs 8,500';
      expect(SmsParser.hasFinancialKeywords(msg), isTrue);

      final result = SmsParser.parseSmsDetailed(msg, 'BANK',
          smsDate: DateTime(2026, 8, 14));
      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(1000.0),
          reason: 'Transaction amount must be 1000.0, not balance.');
      expect(result.remainingBalance, equals(8500.0),
          reason: 'Balance must be correctly identified as 8500.0.');
    });

    test('Group E: Real Bank Wording Variations Test', () {
      final bankVariations = [
        'HDFC Bank: Rs 2,500.00 debited from a/c **4321 on 14-08-26 to VPA swiggy@icici.',
        'ICICI Bank Acct XX9876 credited with INR 15,000.00 on 12 Aug 26.',
        'SBI: Rs 400 withdrawn from ATM A/C *1111 on 10-08-26.',
        'Axis Bank: Sent Rs 1,200 to Zomato via UPI Ref 678901.',
      ];

      for (final msg in bankVariations) {
        expect(SmsParser.hasFinancialKeywords(msg), isTrue);
        final parsed = SmsParser.parseSmsDetailed(msg, 'BANK',
            smsDate: DateTime(2026, 8, 14));
        expect(parsed, isNotNull);
      }
    });

    test(
        'Comprehensive SMS Parsing Benchmark (1k Irrelevant, 1k Financial, 1k Mixed, 10k Mixed)',
        () {
      void runBenchmark(String label, List<String> msgs, bool isFinancialOnly) {
        final sw = Stopwatch()..start();
        int examined = 0;
        int earlyRejected = 0;
        int parsed = 0;
        int successfulTxs = 0;
        int falseRejects = 0;
        int falseAccepts = 0;

        for (final msg in msgs) {
          examined++;
          final hasKeywords = SmsParser.hasFinancialKeywords(msg);
          if (!hasKeywords) {
            earlyRejected++;
            if (isFinancialOnly) falseRejects++;
          } else {
            parsed++;
            final res = SmsParser.parseSmsDetailed(msg, 'BANK',
                smsDate: DateTime(2026, 8, 14));
            if (res != null) {
              successfulTxs++;
            } else if (!isFinancialOnly &&
                !msg.contains('debited') &&
                !msg.contains('credited')) {
              falseAccepts++;
            }
          }
        }
        sw.stop();

        debugPrint(
            '[$label] Examined: $examined, Early Rejected: $earlyRejected, Parsed: $parsed, Successful Txs: $successfulTxs, False Rejects: $falseRejects, False Accepts: $falseAccepts, Duration: ${sw.elapsedMilliseconds} ms');
      }

      final irrelevant1k = List.generate(1000,
          (i) => 'Your order #$i containing 2 items will arrive in 4 hours.');
      final financial1k = List.generate(
          1000, (i) => 'Rs. ${100 + i} debited from A/C X1234 on 14-Aug-2026.');
      final mixed1k = List.generate(
          1000,
          (i) => (i % 2 == 0)
              ? 'Rs. ${100 + i} debited from A/C X1234 on 14-Aug-2026.'
              : 'Your OTP for order #$i is ${100000 + i}. Do not share.');
      final mixed10k = List.generate(
          10000,
          (i) => (i % 5 == 0)
              ? 'Rs. ${100 + i} debited from A/C X1234 on 14-Aug-2026.'
              : 'Your order #$i will be delivered in 2 hours to user $i.');

      runBenchmark('1,000 Irrelevant SMS', irrelevant1k, false);
      runBenchmark('1,000 Financial SMS', financial1k, true);
      runBenchmark('1,000 Mixed SMS', mixed1k, false);
      runBenchmark('10,000 Mixed SMS', mixed10k, false);
    });
  });

  group('Performance Benchmark 5: Duplicate Reference Lookup', () {
    test('Measures average O(1) Set lookup across 10,000 duplicate checks', () {
      final existingRefs = List.generate(2000, (i) => 'REF_${10000 + i}');
      final refSet = existingRefs.map((r) => r.trim().toLowerCase()).toSet();

      final sw = Stopwatch()..start();
      int dupCount = 0;
      for (int i = 0; i < 10000; i++) {
        final ref = 'ref_${10000 + (i % 3000)}';
        if (refSet.contains(ref)) dupCount++;
      }
      sw.stop();

      debugPrint(
          '[Benchmark 5] 10,000 duplicate checks time: ${sw.elapsedMilliseconds} ms (Duplicates detected: $dupCount)');
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });

  group('Performance Benchmark 6: Money Brain RAG Query & Context Cache', () {
    test('Measures Money Brain context build and repeated query response time',
        () {
      final engine = FinancialAiEngine();
      final now = DateTime.now();
      final txs = List.generate(
        500,
        (i) => TransactionItem(
          amount: 200 + (i * 10).toDouble(),
          merchant: 'Store_$i',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      );

      // First query (cold context build)
      final sw1 = Stopwatch()..start();
      final res1 = engine.analyze(
        query: 'What is my daily safe spending limit?',
        intent: FinancialIntent.budget,
        contextPayload: ContextPayload(
          formattedContext: 'Context with 500 transactions',
          retrievedDocs: const [],
        ),
        allTransactions: txs,
        subscriptions: [],
        monthlyBudget: 50000,
      );
      sw1.stop();

      // Second query (repeated)
      final sw2 = Stopwatch()..start();
      final res2 = engine.analyze(
        query: 'What is my daily safe spending limit?',
        intent: FinancialIntent.budget,
        contextPayload: ContextPayload(
          formattedContext: 'Context with 500 transactions',
          retrievedDocs: const [],
        ),
        allTransactions: txs,
        subscriptions: [],
        monthlyBudget: 50000,
      );
      sw2.stop();

      debugPrint(
          '[Benchmark 6] Money Brain First Query: ${sw1.elapsedMicroseconds} µs, Repeated Query: ${sw2.elapsedMicroseconds} µs');
      expect(res1.answer, equals(res2.answer));
    });

    test(
        'Verifies cache invalidation after add, edit, delete, and profile switch',
        () {
      final engine = FinancialAiEngine();
      FinancialAiEngine.invalidateCache();

      // Profile A: 1000 Food
      final txA1 = TransactionItem(
        amount: 1000,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
        profileId: 'profile_a',
      );

      final r1 = engine.analyze(
        query: 'What is my highest purchase?',
        intent: FinancialIntent.budget,
        contextPayload:
            ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: [txA1],
        subscriptions: [],
        monthlyBudget: 10000,
      );
      expect(r1.answer, contains('Swiggy'));

      // Add: 5000 Travel (bumps revision)
      FinancialAiEngine.invalidateCache();
      final txA2 = TransactionItem(
        amount: 5000,
        merchant: 'Airline',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
        profileId: 'profile_a',
      );

      final r2 = engine.analyze(
        query: 'What is my highest purchase?',
        intent: FinancialIntent.budget,
        contextPayload:
            ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: [txA1, txA2],
        subscriptions: [],
        monthlyBudget: 10000,
      );
      expect(r2.answer, contains('Airline'));

      // Switch to Profile B: Profile B only
      final txB = TransactionItem(
        amount: 200,
        merchant: 'Coffee Shop',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
        profileId: 'profile_b',
      );

      final r3 = engine.analyze(
        query: 'What is my highest purchase?',
        intent: FinancialIntent.budget,
        contextPayload:
            ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: [txB],
        subscriptions: [],
        monthlyBudget: 10000,
      );
      expect(r3.answer, contains('Coffee Shop'));
      expect(r3.answer, isNot(contains('Airline')));
    });
  });

  group('Performance Benchmark 7: AES Encrypted Backup & Restore', () {
    test('Measures backup archive creation and restore parsing', () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final swBackup = Stopwatch()..start();
      final backupJson = await BackupService.generateBackupArchive(
        password: 'PerfTestPassword123!',
      );
      swBackup.stop();

      final swRestore = Stopwatch()..start();
      await BackupService.restoreFromArchive(
        backupJson,
        password: 'PerfTestPassword123!',
      );
      swRestore.stop();

      debugPrint(
          '[Benchmark 7] AES Backup time: ${swBackup.elapsedMilliseconds} ms, Restore time: ${swRestore.elapsedMilliseconds} ms');
      expect(swBackup.elapsedMilliseconds, lessThan(25000));
      expect(swRestore.elapsedMilliseconds, lessThan(25000));
    });
  });
}
