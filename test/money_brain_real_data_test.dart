import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/rag/financial_ai_engine.dart';
import 'package:sagiro/rag/rag_provider.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/family_engine/services/family_service.dart';
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
    FinancialAiEngine.invalidateCache();
  });

  group('SAGIRO Money Brain — Real Financial Data Query Engine', () {
    // ── 1. Category Spending: "how much i spend the food" ───────────────────────
    test('1. "how much i spend the food" returns real calculated Food spending',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final txns = [
        TransactionItem(
          amount: 450.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 250.0,
          merchant: 'Zomato',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 1500.0,
          merchant: 'Zara',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('how much i spend the food');

      expect(result.response.answer.contains('Food spending'), isTrue);
      expect(result.response.answer.contains('₹700'), isTrue);
      expect(result.response.answer.contains('2 transactions'), isTrue);
      expect(result.response.answer.contains('Swiggy'), isTrue);
      expect(
          result.response.answer
              .contains('Sagiro is a privacy-first personal finance app'),
          isFalse);
    });

    // ── 2. Category Spending: "How much did I spend on food?" ──────────────────
    test('2. "How much did I spend on food?" matches exact real totals',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final txns = [
        TransactionItem(
          amount: 1200.0,
          merchant: 'Dominos',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('How much did I spend on food?');

      expect(result.response.answer.contains('Food spending'), isTrue);
      expect(result.response.answer.contains('₹1,200'), isTrue);
      expect(result.response.answer.contains('1 transaction'), isTrue);
    });

    // ── 3. Category Empty State: "how much did I spend on fuel" ───────────────
    test('3. Category query with 0 transactions gives honest empty response',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final txns = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('how much did I spend on fuel');

      expect(
          result.response.answer
              .contains('You haven\'t recorded any Fuel expenses this month'),
          isTrue);
      expect(
          result.response.answer
              .contains('Sagiro is a privacy-first personal finance app'),
          isFalse);
    });

    // ── 4. Merchant Spending: "How much did I spend on Swiggy?" ───────────────
    test('4. "How much did I spend on Swiggy?" calculates real merchant totals',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final txns = [
        TransactionItem(
          amount: 320.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 480.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('How much did I spend on Swiggy?');

      expect(result.response.answer.contains('Swiggy spending'), isTrue);
      expect(result.response.answer.contains('₹800'), isTrue);
      expect(result.response.answer.contains('2 transactions'), isTrue);
      expect(result.response.answer.contains('Average ₹400'), isTrue);
    });

    // ── 5. Highest Expense: "Where did I spend the most?" ─────────────────────
    test(
        '5. "Where did I spend the most?" returns highest single expense & categories',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final txns = [
        TransactionItem(
          amount: 250.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 4500.0,
          merchant: 'Croma Electronics',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 600.0,
          merchant: 'Indian Oil',
          category: 'Fuel',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('Where did I spend the most?');

      expect(result.response.answer.contains('₹4,500'), isTrue);
      expect(result.response.answer.contains('Croma Electronics'), isTrue);
      expect(
          result.response.answer.contains('Top spending categories'), isTrue);
    });

    // ── 6. Timeframe Spending: "What did I spend yesterday?" ──────────────────
    test('6. "What did I spend yesterday?" filters strictly to yesterday date',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final txns = [
        TransactionItem(
          amount: 350.0,
          merchant: 'Yesterday Cafe',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: yesterday,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 900.0,
          merchant: 'Today Store',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('What did I spend yesterday?');

      expect(
          result.response.answer.contains('Total spending yesterday'), isTrue);
      expect(result.response.answer.contains('₹350'), isTrue);
      expect(result.response.answer.contains('Yesterday Cafe'), isTrue);
      expect(result.response.answer.contains('Today Store'), isFalse);
    });

    // ── 7. Month Spending: "How much did I spend this month?" ─────────────────
    test(
        '7. "How much did I spend this month?" aggregates current month debits',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final txns = [
        TransactionItem(
          amount: 1000.0,
          merchant: 'Rent Advance',
          category: 'Bills',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 500.0,
          merchant: 'Supermarket',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('How much did I spend this month?');

      expect(
          result.response.answer.contains('Total spending this month'), isTrue);
      expect(result.response.answer.contains('₹1,500 total'), isTrue);
      expect(result.response.answer.contains('2 transactions'), isTrue);
    });

    // ── 8. Budget Remaining: "How much money do I have left from my budget?" ──
    test(
        '8. "How much money do I have left from my budget?" calculates Safe Today',
        () async {
      final db = DatabaseHelper.instance;
      await db.setSetting('monthly_budget', '30000');
      final now = DateTime.now();

      final txns = [
        TransactionItem(
          amount: 5000.0,
          merchant: 'Appliance',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];
      await db.insertTransactionBatch(txns);

      final ragProvider = RagProvider();
      final result = await ragProvider
          .queryMoneyBrain('How much money do I have left from my budget?');

      expect(result.response.answer.contains('Safe Today™ spending limit'),
          isTrue);
      expect(
          result.response.answer
              .contains('₹25,000 remaining from your ₹30,000 monthly budget'),
          isTrue);
    });

    // ── 9. Profile Isolation: Profile A vs Profile B ──────────────────────────
    test(
        '9. Profile isolation: Money Brain only sees active profile transactions',
        () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();

      // Insert for Alice
      await db.insertTransactionBatch([
        TransactionItem(
          amount: 999.0,
          merchant: 'Alice Exclusive Store',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'profile_alice',
        ),
      ]);

      // Insert for Bob
      await db.insertTransactionBatch([
        TransactionItem(
          amount: 222.0,
          merchant: 'Bob Private Store',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'profile_bob',
        ),
      ]);

      // Switch to Alice
      await FamilyService.instance.setActiveProfileId('profile_alice');
      final ragProviderAlice = RagProvider();
      final resultAlice = await ragProviderAlice
          .queryMoneyBrain('How much did I spend this month?');

      expect(resultAlice.response.answer.contains('₹999'), isTrue);
      expect(resultAlice.response.answer.contains('Alice Exclusive Store'),
          isTrue);
      expect(
          resultAlice.response.answer.contains('Bob Private Store'), isFalse);
      expect(resultAlice.response.answer.contains('₹222'), isFalse);

      // Switch to Bob
      await FamilyService.instance.setActiveProfileId('profile_bob');
      FinancialAiEngine.invalidateCache();
      final ragProviderBob = RagProvider();
      final resultBob = await ragProviderBob
          .queryMoneyBrain('How much did I spend this month?');

      expect(resultBob.response.answer.contains('₹222'), isTrue);
      expect(resultBob.response.answer.contains('Bob Private Store'), isTrue);
      expect(
          resultBob.response.answer.contains('Alice Exclusive Store'), isFalse);
      expect(resultBob.response.answer.contains('₹999'), isFalse);
    });

    // ── 10. Cache Invalidation after new Transaction ──────────────────────────
    test(
        '10. Money Brain cache invalidates and updates when new transaction is added',
        () async {
      await FamilyService.instance.setActiveProfileId('default_profile');
      final db = DatabaseHelper.instance;
      final now = DateTime.now();

      // Initial transaction
      await db.insertTransaction(TransactionItem(
        amount: 300.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: now,
        profileId: 'default_profile',
      ));

      final ragProvider = RagProvider();
      final firstRes =
          await ragProvider.queryMoneyBrain('how much i spend the food');
      expect(firstRes.response.answer.contains('₹300'), isTrue);

      // Add second transaction via provider
      final budgetProvider = BudgetProvider();
      await budgetProvider.loadData();
      await budgetProvider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'Zomato',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: now,
        profileId: 'default_profile',
      ));

      // Query again
      final secondRes =
          await ragProvider.queryMoneyBrain('how much i spend the food');
      expect(secondRes.response.answer.contains('₹800'), isTrue);
      expect(secondRes.response.answer.contains('2 transactions'), isTrue);
    });
  });
}
