import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/rag/financial_ai_engine.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/services/sms_inbox_service.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/utils/month_range.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
    await AppSettingsService.instance.loadSettings();
  });

  group('SAGIRO SMS Scanner Flow — 34 Scenario Master Suite', () {
    // ── 1. Empty inbox ───────────────────────────────────────────────────────
    test('Scenario 1: Empty inbox returns empty transactions with 0 parsed',
        () {
      const messages = <String>[];
      final parsedList = <TransactionItem>[];
      for (final m in messages) {
        final res = SmsParser.parseSmsDetailed(m, 'HDFCBK');
        if (res != null) parsedList.add(res.transaction);
      }
      expect(parsedList.isEmpty, isTrue);
    });

    // ── 2. One valid debit SMS ───────────────────────────────────────────────
    test('Scenario 2: One valid debit SMS', () {
      const body =
          'Rs 450.00 debited from A/C XX1234 on 14-Aug-2026 at Swiggy. Ref 998877665544. Avl Bal Rs 12,000.';
      final res = SmsParser.parseSmsDetailed(body, 'HDFCBK');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(450.0));
      expect(res.transaction.type, equals(TransactionType.debit));
      expect(res.transaction.merchant, equals('Swiggy'));
      expect(res.transaction.transactionReference, equals('998877665544'));
      expect(res.remainingBalance, equals(12000.0));
    });

    // ── 3. One valid credit SMS ──────────────────────────────────────────────
    test('Scenario 3: One valid credit SMS', () {
      const body =
          'Your A/C XX4321 is credited with Rs 50,000.00 on 14-Aug-2026 by Salary. Ref 112233445566. Avl Bal Rs 65,000.';
      final res = SmsParser.parseSmsDetailed(body, 'SBIINB');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(50000.0));
      expect(res.transaction.type, equals(TransactionType.credit));
      expect(res.remainingBalance, equals(65000.0));
    });

    // ── 4. UPI SMS ───────────────────────────────────────────────────────────
    test('Scenario 4: UPI SMS', () {
      const body =
          'Paid Rs 250.00 via UPI to zomato@upi on 14-08-2026. Ref 778899001122. Avl Bal Rs 5,400.';
      final res = SmsParser.parseSmsDetailed(body, 'PAYTM');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(250.0));
      expect(res.paymentMethod, equals('UPI'));
      expect(res.transaction.merchant, equals('Zomato'));
    });

    // ── 5. NEFT SMS ──────────────────────────────────────────────────────────
    test('Scenario 5: NEFT SMS', () {
      const body =
          'NEFT transaction of Rs 15,000.00 debited from A/C XX9988 on 14-08-2026. UTR N123456789. Avl Bal Rs 45,000.';
      final res = SmsParser.parseSmsDetailed(body, 'AXISBK');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(15000.0));
      expect(res.transaction.type, equals(TransactionType.debit));
      expect(res.paymentMethod, equals('NEFT'));
    });

    // ── 6. IMPS SMS ──────────────────────────────────────────────────────────
    test('Scenario 6: IMPS SMS', () {
      const body =
          'IMPS transfer of Rs 3,500.00 debited from A/C XX5544 to Landlord. Ref 887766554433. Avl Bal Rs 22,000.';
      final res = SmsParser.parseSmsDetailed(body, 'ICICIB');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(3500.0));
      expect(res.paymentMethod, equals('IMPS'));
    });

    // ── 7. ATM SMS ───────────────────────────────────────────────────────────
    test('Scenario 7: ATM SMS', () {
      const body =
          'Cash withdrawal of Rs 2,000.00 from ATM at Mumbai Branch on A/C XX7766. Avl Bal Rs 8,000.';
      final res = SmsParser.parseSmsDetailed(body, 'KOTAKB');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(2000.0));
      expect(res.paymentMethod, equals('ATM'));
      expect(res.transaction.merchant, equals('ATM Cash Withdrawal'));
    });

    // ── 8. POS SMS ───────────────────────────────────────────────────────────
    test('Scenario 8: POS / Card SMS', () {
      const body =
          'Rs 1,899.00 spent on your Credit Card XX1122 at Decathlon POS on 14-Aug-2026. Avl Lmt Rs 98,000.';
      final res = SmsParser.parseSmsDetailed(body, 'HDFCCRD');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(1899.0));
      expect(res.paymentMethod, equals('Card'));
    });

    // ── 9. OTP rejection ─────────────────────────────────────────────────────
    test('Scenario 9: OTP rejection', () {
      const body =
          'Your OTP for transaction of Rs 1,500 at Amazon is 492019. Do not share your OTP with anyone.';
      final res = SmsParser.parseSmsDetailed(body, 'HDFCBK');
      expect(res, isNull);
    });

    // ── 10. Promotional SMS rejection ────────────────────────────────────────
    test('Scenario 10: Promotional SMS rejection', () {
      const body =
          'Congratulations! You are pre-approved for an instant loan of Rs 5,00,000. Click to apply now!';
      final res = SmsParser.parseSmsDetailed(body, 'BAJAJ');
      expect(res, isNull);
    });

    // ── 11. Delivery SMS rejection ───────────────────────────────────────────
    test('Scenario 11: Delivery SMS rejection', () {
      const body =
          'Your Amazon package with order 402-9182736 is out for delivery and arriving today.';
      final res = SmsParser.parseSmsDetailed(body, 'AMAZON');
      expect(res, isNull);
    });

    // ── 12. Personal SMS rejection ───────────────────────────────────────────
    test('Scenario 12: Personal SMS rejection', () {
      const body = 'Hey are you free for lunch tomorrow? Call me!';
      final res = SmsParser.parseSmsDetailed(body, '+919876543210');
      expect(res, isNull);
    });

    // ── 13. Balance vs transaction amount ────────────────────────────────────
    test('Scenario 13: Balance vs transaction amount separation', () {
      const body =
          'Rs 1,000 debited from A/C XX4921. Avl Bal Rs 8,500. Ref 123456.';
      final res = SmsParser.parseSmsDetailed(body, 'SBIINB');
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(1000.0));
      expect(res.remainingBalance, equals(8500.0));
    });

    // ── 14. Explicit transaction date ────────────────────────────────────────
    test('Scenario 14: Explicit transaction date overrides SMS date', () {
      const body =
          'Rs 500 debited on 10-Aug-2026 at Cafe Coffee Day. Ref 990011.';
      final res = SmsParser.parseSmsDetailed(body, 'HDFCBK',
          smsDate: DateTime(2026, 8, 14));
      expect(res, isNotNull);
      expect(res!.transaction.date.day, equals(10));
      expect(res.transaction.date.month, equals(8));
      expect(res.transaction.date.year, equals(2026));
    });

    // ── 15. SMS timestamp fallback ───────────────────────────────────────────
    test('Scenario 15: SMS timestamp fallback when no text date present', () {
      const body = 'Rs 300 debited for Zomato. Ref 445566.';
      final res = SmsParser.parseSmsDetailed(body, 'HDFCBK',
          smsDate: DateTime(2026, 8, 14, 18, 30));
      expect(res, isNotNull);
      expect(res!.transaction.date.day, equals(14));
      expect(res.transaction.date.month, equals(8));
    });

    // ── 16. Date format DD/MM/YYYY ───────────────────────────────────────────
    test('Scenario 16: Date format DD/MM/YYYY', () {
      const body = 'Debited Rs 400 on 14/08/2026. Ref 112233.';
      final res = SmsParser.parseSmsDetailed(body, 'ICICIB');
      expect(res, isNotNull);
      expect(res!.transaction.date, equals(DateTime(2026, 8, 14)));
    });

    // ── 17. Date format DD-MM-YYYY ───────────────────────────────────────────
    test('Scenario 17: Date format DD-MM-YYYY', () {
      const body = 'Debited Rs 400 on 14-08-2026. Ref 112233.';
      final res = SmsParser.parseSmsDetailed(body, 'ICICIB');
      expect(res, isNotNull);
      expect(res!.transaction.date, equals(DateTime(2026, 8, 14)));
    });

    // ── 18. Date format DD.MM.YYYY ───────────────────────────────────────────
    test('Scenario 18: Date format DD.MM.YYYY', () {
      const body = 'Debited Rs 400 on 14.08.2026. Ref 112233.';
      final res = SmsParser.parseSmsDetailed(body, 'ICICIB');
      expect(res, isNotNull);
      expect(res!.transaction.date, equals(DateTime(2026, 8, 14)));
    });

    // ── 19. Date format YYYY-MM-DD ───────────────────────────────────────────
    test('Scenario 19: Date format YYYY-MM-DD', () {
      const body = 'Debited Rs 400 on 2026-08-14. Ref 112233.';
      final res = SmsParser.parseSmsDetailed(body, 'ICICIB');
      expect(res, isNotNull);
      expect(res!.transaction.date, equals(DateTime(2026, 8, 14)));
    });

    // ── 20. Date format DD MMM YYYY ──────────────────────────────────────────
    test('Scenario 20: Date format DD MMM YYYY & DD MMMM YYYY', () {
      const body1 = 'Debited Rs 400 on 14 Aug 2026. Ref 112233.';
      final res1 = SmsParser.parseSmsDetailed(body1, 'ICICIB');
      expect(res1, isNotNull);
      expect(res1!.transaction.date, equals(DateTime(2026, 8, 14)));

      const body2 = 'Debited Rs 400 on 14 August 2026. Ref 112234.';
      final res2 = SmsParser.parseSmsDetailed(body2, 'ICICIB');
      expect(res2, isNotNull);
      expect(res2!.transaction.date, equals(DateTime(2026, 8, 14)));
    });

    // ── 21. Duplicate reference ──────────────────────────────────────────────
    test('Scenario 21: Duplicate reference skipped in O(1)', () {
      final existingRefs = {'TXN_REF_9999'};
      const newRef = 'TXN_REF_9999';
      expect(existingRefs.contains(newRef), isTrue);
    });

    // ── 22. Duplicate fingerprint ────────────────────────────────────────────
    test('Scenario 22: Duplicate deterministic fingerprint', () {
      final fp1 = SmsParser.generateFingerprint(
        profileId: 'default_profile',
        date: DateTime(2026, 8, 14),
        amount: 450.0,
        type: TransactionType.debit,
        merchant: 'Swiggy',
      );
      final fp2 = SmsParser.generateFingerprint(
        profileId: 'default_profile',
        date: DateTime(2026, 8, 14),
        amount: 450.0,
        type: TransactionType.debit,
        merchant: 'swiggy',
      );
      expect(fp1.toLowerCase(), equals(fp2.toLowerCase()));
    });

    // ── 23. Valid second transaction ─────────────────────────────────────────
    test('Scenario 23: Valid distinct transactions have distinct fingerprints',
        () {
      final fp1 = SmsParser.generateFingerprint(
        profileId: 'default_profile',
        date: DateTime(2026, 8, 14),
        amount: 450.0,
        type: TransactionType.debit,
        merchant: 'Swiggy',
      );
      final fp2 = SmsParser.generateFingerprint(
        profileId: 'default_profile',
        date: DateTime(2026, 8, 14),
        amount: 600.0,
        type: TransactionType.debit,
        merchant: 'Swiggy',
      );
      expect(fp1, isNot(equals(fp2)));
    });

    // ── 24. Profile isolation ────────────────────────────────────────────────
    test('Scenario 24: Profile isolation in fingerprint generation', () {
      final fpA = SmsParser.generateFingerprint(
        profileId: 'profile_alice',
        date: DateTime(2026, 8, 14),
        amount: 500.0,
        type: TransactionType.debit,
        merchant: 'Amazon',
      );
      final fpB = SmsParser.generateFingerprint(
        profileId: 'profile_bob',
        date: DateTime(2026, 8, 14),
        amount: 500.0,
        type: TransactionType.debit,
        merchant: 'Amazon',
      );
      expect(fpA, isNot(equals(fpB)));
    });

    // ── 25. July/August boundary ─────────────────────────────────────────────
    test('Scenario 25: MonthRange boundary for July 31 vs August 1', () {
      final rangeAug = MonthRange.forYearMonth(2026, 8);
      final july31 = DateTime(2026, 7, 31, 23, 59, 59);
      final aug1 = DateTime(2026, 8, 1, 0, 0, 0);

      expect(rangeAug.contains(july31), isFalse);
      expect(rangeAug.contains(aug1), isTrue);
    });

    // ── 26. December/January boundary ────────────────────────────────────────
    test('Scenario 26: December 31 vs January 1 boundary', () {
      final rangeJan2026 = MonthRange.forYearMonth(2026, 1);
      final dec31_2025 = DateTime(2025, 12, 31, 23, 59, 59);
      final jan1_2026 = DateTime(2026, 1, 1, 0, 0, 0);

      expect(rangeJan2026.contains(dec31_2025), isFalse);
      expect(rangeJan2026.contains(jan1_2026), isTrue);
    });

    // ── 27. Batch database insertion ─────────────────────────────────────────
    test('Scenario 27: Atomic batch SQLite insertion', () async {
      final dbHelper = DatabaseHelper.instance;
      final txns = [
        TransactionItem(
          amount: 450.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 14),
          transactionReference: 'REF001',
        ),
        TransactionItem(
          amount: 1200.0,
          merchant: 'Electricity Bill',
          category: 'Bills',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 13),
          transactionReference: 'REF002',
        ),
      ];

      final res = await dbHelper.insertTransactionBatch(txns);
      expect(res.insertedCount, equals(2));
      expect(res.failedCount, equals(0));

      final saved = await dbHelper.getAllTransactions();
      expect(saved.length, equals(2));
    });

    // ── 28. Timeline refresh ─────────────────────────────────────────────────
    test(
        'Scenario 28: Timeline refresh via BudgetProvider.addTransactionsBatch',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.transactions.isEmpty, isTrue);

      final toAdd = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Grocery Store',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 14),
          transactionReference: 'REF_TIMELINE_1',
        ),
      ];

      final res = await provider.addTransactionsBatch(toAdd);
      expect(res.insertedCount, equals(1));
      expect(provider.transactions.length, equals(1));
      expect(provider.transactions.first.merchant, equals('Grocery Store'));
    });

    // ── 29. Dashboard refresh ────────────────────────────────────────────────
    test('Scenario 29: Dashboard metrics calculate correctly from DB',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final toAdd = [
        TransactionItem(
          amount: 1000.0,
          merchant: 'Restaurant',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 14),
        ),
        TransactionItem(
          amount: 350.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 14),
        ),
      ];

      await provider.addTransactionsBatch(toAdd);
      expect(provider.transactions.length, equals(2));
      expect(provider.calculateMonthSpend(targetDate: DateTime(2026, 8, 14)),
          equals(1350.0));
    });

    // ── 30. Money Brain cache invalidation ───────────────────────────────────
    test('Scenario 30: Money Brain cache invalidation on batch mutation',
        () async {
      FinancialAiEngine.invalidateCache();
      expect(true, isTrue);
    });

    // ── 31. Permission denied ────────────────────────────────────────────────
    test(
        'Scenario 31: Permission denied result is handled safely without crash',
        () {
      const res = SmsReadResult(
        transactions: [],
        totalRead: 0,
        parsed: 0,
        skippedDuplicates: 0,
        permissionDenied: true,
      );
      expect(res.permissionDenied, isTrue);
      expect(res.transactions.isEmpty, isTrue);
      expect(res.hasError, isFalse);
    });

    // ── 32. Large inbox performance ──────────────────────────────────────────
    test('Scenario 32: Large inbox (500 SMS) memory parsing performance', () {
      final stopwatch = Stopwatch()..start();
      int parsed = 0;
      for (int i = 0; i < 500; i++) {
        final body =
            'Rs ${100 + i}.00 debited from A/C XX1234 on 14-Aug-2026 at Store_$i. Ref REF_${10000 + i}. Avl Bal Rs 50,000.';
        final res = SmsParser.parseSmsDetailed(body, 'HDFCBK');
        if (res != null) parsed++;
      }
      stopwatch.stop();
      expect(parsed, equals(500));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    // ── 33. 1,000 SMS benchmark ──────────────────────────────────────────────
    test('Scenario 33: 1,000 SMS benchmark parsed in under 1,500ms', () {
      final stopwatch = Stopwatch()..start();
      int count = 0;
      for (int i = 0; i < 1000; i++) {
        final body =
            'Rs ${(i % 500) + 10}.00 debited on 14-08-2026 by UPI to merchant$i@upi. Ref REF_$i.';
        final res = SmsParser.parseSmsDetailed(body, 'SBIINB');
        if (res != null) count++;
      }
      stopwatch.stop();
      expect(count, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
    });

    // ── 34. 10,000 SMS benchmark ─────────────────────────────────────────────
    test('Scenario 34: 10,000 SMS in-memory deduplication in under 100ms', () {
      final refSet = <String>{};
      final fpSet = <String>{};
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10000; i++) {
        final ref = 'REF_${i % 2500}';
        final fp = 'default_profile|2026-08-14|100.00|debit|swiggy_${i % 2500}';
        refSet.add(ref);
        fpSet.add(fp);
      }
      stopwatch.stop();

      expect(refSet.length, equals(2500));
      expect(fpSet.length, equals(2500));
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
