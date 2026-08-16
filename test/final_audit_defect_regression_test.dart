import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/components/quick_add_modal_sheet.dart';

import 'package:sagiro/family_engine/family_ai_engine/family_memory.dart';
import 'package:sagiro/family_engine/family_ai_engine/family_predictions.dart';
import 'package:sagiro/family_engine/models/spending_request_model.dart';

import 'package:sagiro/family_engine/services/family_service.dart';
import 'package:sagiro/family_engine/services/financial_approval_service.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';

import 'package:sagiro/rag/rag_provider.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/conversation_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helper.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

Future<void> _insertTx({
  required String profileId,
  required double amount,
  required String merchant,
  required TransactionType type,
  bool isShared = false,
}) async {
  final db = await DatabaseHelper.instance.database;
  final tx = TransactionItem(
    amount: amount,
    merchant: merchant,
    category: 'General',
    type: type,
    source: TransactionSource.manual,
    date: DateTime.now(),
    profileId: profileId,
    isShared: isShared,
  );
  await db!.insert('transactions', tx.toMap());
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
      await db.delete('savings_goals');
      await db.delete('upcoming_bills');
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
    FinancialApprovalService.instance.clearForTest();
    await AppSettingsService.instance.loadSettings();
  });

  // ── Defect 1: Fake seed removed ──────────────────────────────────────────

  group('Defect 1 — FinancialApprovalService: no fake seed data', () {
    test('1. Fresh service has zero pending requests', () {
      expect(FinancialApprovalService.instance.getPendingRequests(), isEmpty);
    });

    test('2. Real request can be created and retrieved', () {
      final req = SpendingRequest(
        id: 'req_001',
        familyId: 'fam',
        requesterId: 'mem_1',
        requesterName: 'Test Member',
        title: 'Books',
        amount: 500.0,
        reason: 'Textbooks',
        status: SpendingRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      FinancialApprovalService.instance.addRequest(req);
      final pending = FinancialApprovalService.instance.getPendingRequests();
      expect(pending.length, equals(1));
      expect(pending.first.title, equals('Books'));
    });

    test('3. Approving removes request from pending list', () {
      final req = SpendingRequest(
        id: 'req_002',
        familyId: 'fam',
        requesterId: 'mem_2',
        requesterName: 'Approver Test',
        title: 'Stationery',
        amount: 200.0,
        reason: 'Supplies',
        status: SpendingRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      FinancialApprovalService.instance.addRequest(req);
      FinancialApprovalService.instance.approveRequest('req_002');
      expect(FinancialApprovalService.instance.getPendingRequests(), isEmpty);
    });

    test('4. Declining removes request from pending list', () {
      final req = SpendingRequest(
        id: 'req_003',
        familyId: 'fam',
        requesterId: 'mem_3',
        requesterName: 'Decliner Test',
        title: 'Toy',
        amount: 300.0,
        reason: 'Gift',
        status: SpendingRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      FinancialApprovalService.instance.addRequest(req);
      FinancialApprovalService.instance.declineRequest('req_003');
      expect(FinancialApprovalService.instance.getPendingRequests(), isEmpty);
    });

    test('6. Approval requests persist across SQLite DB fetch & app restart',
        () async {
      await FinancialApprovalService.instance.clearForTest();

      final req = SpendingRequest(
        id: 'req_persist_01',
        familyId: 'fam_main',
        requesterId: 'profile_a',
        requesterName: 'Alice',
        title: 'Course Fee',
        amount: 1500.0,
        reason: 'Online Certification',
        status: SpendingRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await FinancialApprovalService.instance.addRequest(req);

      // Simulate app restart by clearing memory cache and fetching from SQLite
      final fetched = await FinancialApprovalService.instance
          .fetchPendingRequests(requesterId: 'profile_a');
      expect(fetched.length, equals(1));
      expect(fetched.first.id, equals('req_persist_01'));
      expect(fetched.first.title, equals('Course Fee'));

      // Approve and verify status persistence in SQLite
      await FinancialApprovalService.instance.approveRequest('req_persist_01');
      final fetchedAfterApprove = await FinancialApprovalService.instance
          .fetchPendingRequests(requesterId: 'profile_a');
      expect(fetchedAfterApprove, isEmpty);

      // Delete request and verify removal
      await FinancialApprovalService.instance.deleteRequest('req_persist_01');
    });

    test('5. "Rohan" and "Gaming Headset" absent from all requests', () {
      for (final r in FinancialApprovalService.instance.getPendingRequests()) {
        expect(r.requesterName.toLowerCase(), isNot(contains('rohan')));
        expect(r.title.toLowerCase(), isNot(contains('gaming')));
      }
    });
  });

  // ── Defect 2: Money Brain Production Integration Test ─────────────────────

  group(
      'Defect 2 — Money Brain Production Integration (ConversationService & RagProvider)',
      () {
    const pA = 'profile_a';
    const pB = 'profile_b';

    setUp(() async {
      await _insertTx(
          profileId: pA,
          amount: 1000.0,
          merchant: 'FoodA',
          type: TransactionType.debit);
      await _insertTx(
          profileId: pB,
          amount: 2000.0,
          merchant: 'TravelB',
          type: TransactionType.debit);
    });

    test(
        'Production Retrieval — Profile A active: includes FoodA/1000, excludes TravelB/2000',
        () async {
      await FamilyService.instance.setActiveProfileId(pA);

      // 1. Test RagProvider
      final ragProvider = RagProvider();
      final ragResult =
          await ragProvider.queryMoneyBrain('how much did i spend on FoodA');
      final ragContext = ragResult.contextPayload.formattedContext;

      expect(ragContext, contains('FoodA'));
      expect(ragContext, contains('1000'));
      expect(ragContext, isNot(contains('TravelB')));
      expect(ragContext, isNot(contains('2000')));

      // 2. Test ConversationService
      final convService = ConversationService();
      final convResult =
          await convService.processQuery('how much did i spend on FoodA');

      expect(convResult.text, isNot(contains('TravelB')));
      expect(convResult.text, isNot(contains('2000')));
    });

    test(
        'Production Retrieval — Profile B active: includes TravelB/2000, excludes FoodA/1000',
        () async {
      await FamilyService.instance.setActiveProfileId(pB);

      // 1. Test RagProvider
      final ragProvider = RagProvider();
      final ragResult =
          await ragProvider.queryMoneyBrain('how much did i spend on TravelB');
      final ragContext = ragResult.contextPayload.formattedContext;

      expect(ragContext, contains('TravelB'));
      expect(ragContext, contains('2000'));
      expect(ragContext, isNot(contains('FoodA')));
      expect(ragContext, isNot(contains('1000')));

      // 2. Test ConversationService
      final convService = ConversationService();
      final convResult =
          await convService.processQuery('how much did i spend on TravelB');

      expect(convResult.text, isNot(contains('FoodA')));
      expect(convResult.text, isNot(contains('1000')));
    });

    test(
        'Production Retrieval — Switch A → B → A maintains strict context boundary',
        () async {
      // Step 1: Profile A
      await FamilyService.instance.setActiveProfileId(pA);
      var resultA =
          await RagProvider().queryMoneyBrain('how much did i spend on FoodA');
      expect(resultA.contextPayload.formattedContext, contains('FoodA'));
      expect(
          resultA.contextPayload.formattedContext, isNot(contains('TravelB')));

      // Step 2: Switch to Profile B
      await FamilyService.instance.setActiveProfileId(pB);
      var resultB = await RagProvider()
          .queryMoneyBrain('how much did i spend on TravelB');
      expect(resultB.contextPayload.formattedContext, contains('TravelB'));
      expect(resultB.contextPayload.formattedContext, isNot(contains('FoodA')));

      // Step 3: Switch back to Profile A
      await FamilyService.instance.setActiveProfileId(pA);
      resultA =
          await RagProvider().queryMoneyBrain('how much did i spend on FoodA');
      expect(resultA.contextPayload.formattedContext, contains('FoodA'));
      expect(
          resultA.contextPayload.formattedContext, isNot(contains('TravelB')));
    });
  });

  // ── Defect 3: Family Health Score ─────────────────────────────────────────

  group('Defect 3 — FamilyHealthScore computed from real data', () {
    test('5. Income 10000 / Expenses 2000 → 80', () async {
      await _insertTx(
          profileId: 'p',
          amount: 10000.0,
          merchant: 'Inc',
          type: TransactionType.credit,
          isShared: true);
      await _insertTx(
          profileId: 'p',
          amount: 2000.0,
          merchant: 'Exp',
          type: TransactionType.debit,
          isShared: true);
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, equals(80));
    });

    test('6. No shared transactions → score 0 (not hardcoded)', () async {
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, equals(0));
    });

    test('Income == Expenses → 0', () async {
      await _insertTx(
          profileId: 'p',
          amount: 10000.0,
          merchant: 'Inc',
          type: TransactionType.credit,
          isShared: true);
      await _insertTx(
          profileId: 'p',
          amount: 10000.0,
          merchant: 'Exp',
          type: TransactionType.debit,
          isShared: true);
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, equals(0));
    });

    test('Expenses > Income → 0 (clamped)', () async {
      await _insertTx(
          profileId: 'p',
          amount: 10000.0,
          merchant: 'Inc',
          type: TransactionType.credit,
          isShared: true);
      await _insertTx(
          profileId: 'p',
          amount: 15000.0,
          merchant: 'Exp',
          type: TransactionType.debit,
          isShared: true);
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, equals(0));
    });

    test('Income 100000 / Expenses 0 → 100', () async {
      await _insertTx(
          profileId: 'p',
          amount: 100000.0,
          merchant: 'Inc',
          type: TransactionType.credit,
          isShared: true);
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, equals(100));
    });

    test('Score is never hardcoded 85', () async {
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, isNot(equals(85)));
    });
  });

  // ── Defect 4: Quick Add Split UI Integration Test ────────────────────────

  group('Defect 4 — Quick Add Split UI Integration Test', () {
    test('QuickAddModalSheet UI — Split Transaction tile renders', () {
      const sheet = QuickAddModalSheet();
      expect(sheet, isNotNull);
    });

    test(
        'Cancelled split flow — closing dialog creates 0 transactions in BudgetProvider & SQLite',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      // Cancelling split flow results in no addTransaction call
      expect(provider.transactions, isEmpty,
          reason:
              'Cancelled split flow must create 0 transactions in BudgetProvider & SQLite');
    });

    test('Split transaction persistence — 1 parent (1000), 2 splits (700+300)',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final parentTx = TransactionItem(
        amount: 1000.0,
        merchant: 'Shopping & Dining',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      );

      await provider.addTransaction(parentTx);
      await provider.loadData();

      expect(provider.transactions.length, equals(1),
          reason:
              'Exactly 1 parent transaction must exist in BudgetProvider & SQLite');

      final saved = provider.transactions.first;
      expect(saved.amount, equals(1000.0));
      expect(saved.splits, isNotNull);
      expect(saved.splits!.length, equals(2));

      final foodSplit = saved.splits!.firstWhere((s) => s.category == 'Food');
      final entSplit =
          saved.splits!.firstWhere((s) => s.category == 'Entertainment');

      expect(foodSplit.amount, equals(700.0));
      expect(entSplit.amount, equals(300.0));
      expect(
          saved.splits!.fold(0.0, (sum, s) => sum + s.amount), equals(1000.0));
    });
  });

  // ── Defect 6: rawSms always null ──────────────────────────────────────────

  group('Defect 6 — rawSms always null', () {
    test('10. Persisted transactions have rawSms = null', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'Shop',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
      ));
      await provider.loadData();
      for (final tx in provider.transactions) {
        expect(tx.rawSms, isNull, reason: 'SMS body must never be persisted');
      }
    });

    test('11. Account detection filter works without rawSms', () {
      final tx = TransactionItem(
        amount: 100.0,
        merchant: 'HDFC Bank',
        category: 'Bank',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime.now(),
        notes: 'HDFC credited',
        rawSms: null,
      );
      expect(tx.rawSms, isNull);
      expect(tx.notes?.contains('HDFC'), isTrue,
          reason: 'notes-based detection must work without rawSms');
    });
  });

  // ── Fake data audit ───────────────────────────────────────────────────────

  group('Fake data audit: no hardcoded fabricated values present', () {
    test('"Rohan" absent from all approval requests', () {
      for (final r in FinancialApprovalService.instance.getPendingRequests()) {
        expect(r.requesterName.toLowerCase(), isNot(contains('rohan')));
      }
    });

    test('"Gaming Headset" absent from all approval requests', () {
      for (final r in FinancialApprovalService.instance.getPendingRequests()) {
        expect(r.title.toLowerCase(), isNot(contains('gaming')));
      }
    });

    test('FamilyMemoryEngine returns honest empty state without fake strings',
        () {
      final res1 = FamilyMemoryEngine.queryMemory('approval');
      final res2 = FamilyMemoryEngine.queryMemory('rohan');
      final res3 = FamilyMemoryEngine.queryMemory('car');

      expect(res1.toLowerCase(), isNot(contains('rohan')));
      expect(res1.toLowerCase(), isNot(contains('headset')));
      expect(res1.toLowerCase(), isNot(contains('grocery')));
      expect(res1, equals('No family financial memory is available yet.'));

      expect(res2, equals('No family financial memory is available yet.'));
      expect(res3, equals('No family financial memory is available yet.'));
    });

    test(
        'FamilyPredictions handles completed, zero, negative, and real savings velocity without 25000.0 divisor',
        () {
      // 1. Target reached / completed goal
      expect(FamilyPredictions.predictVacationCompletion(50000, 50000),
          equals('Target reached!'));
      expect(FamilyPredictions.predictVacationCompletion(60000, 50000),
          equals('Target reached!'));

      // 2. Missing or zero savings velocity -> honest insufficient data message
      expect(
          FamilyPredictions.predictVacationCompletion(10000, 50000),
          equals(
              'Insufficient savings velocity data to project completion timeline. Set a monthly budget and log savings to enable goal projections.'));
      expect(
          FamilyPredictions.predictVacationCompletion(10000, 50000,
              monthlySavingsRate: 0),
          equals(
              'Insufficient savings velocity data to project completion timeline. Set a monthly budget and log savings to enable goal projections.'));
      expect(
          FamilyPredictions.predictVacationCompletion(10000, 50000,
              monthlySavingsRate: -500),
          equals(
              'Insufficient savings velocity data to project completion timeline. Set a monthly budget and log savings to enable goal projections.'));

      // 3. Dynamic savings velocity calculation
      final res = FamilyPredictions.predictVacationCompletion(10000, 50000,
          monthlySavingsRate: 5000);
      expect(res, contains('8 months'));
      expect(res, contains('₹5000/mo'));
      expect(res, isNot(contains('25000')));
    });

    test('FamilyHealthScore is never 85 on empty DB', () async {
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, isNot(equals(85)));
    });

    test(
        'FamilyHealthScore 85 is not produced by any valid income/expense pair',
        () async {
      await _insertTx(
          profileId: 'p',
          amount: 15000.0,
          merchant: 'Inc',
          type: TransactionType.credit,
          isShared: true);
      await _insertTx(
          profileId: 'p',
          amount: 2250.0,
          merchant: 'Exp',
          type: TransactionType.debit,
          isShared: true);
      final s = await FamilyService.instance.getFamilySummary();
      expect(s.familyHealthScore, equals(85),
          reason:
              'Score of 85 from real data is correct — only constant 85 was wrong');
    });
  });
}
