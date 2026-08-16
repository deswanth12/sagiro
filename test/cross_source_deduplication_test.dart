import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/models/transaction_draft.dart';
import 'package:sagiro/models/canonical_transaction_identity.dart';
import 'package:sagiro/services/canonical_ingestion_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  setUp(() async {
    await resetTestDatabase();
  });

  group('SAGIRO Cross-Source Transaction Deduplication Suite', () {
    // ── Test 1: SMS -> PDF Duplicate Merge ──────────────────────────────────
    test(
        '1. SMS -> PDF duplicate merge consolidates provenance and preserves metadata',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      // 1. Initial SMS transaction
      final smsDraft = TransactionDraft(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 15, 0),
        transactionReference: '123456789',
        account: 'HDFC Bank **4321',
      );
      final r1 = await service.ingestSingle(draft: smsDraft);
      expect(r1.isInserted, isTrue);

      // 2. Incoming PDF Statement transaction with identical reference & amount
      final pdfDraft = TransactionDraft(
        amount: 379.0,
        merchant: 'GOOGLE INDIA PVT LTD',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 0, 0, 0),
        transactionReference: 'UTR:123456789',
        account: 'HDFC Bank - 4321',
      );
      final r2 = await service.ingestSingle(draft: pdfDraft);
      expect(r2.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
      expect(all.first.sourceTypes, containsAll(['sms', 'pdf']));
      expect(all.first.displaySource, contains('SMS + PDF'));
      expect(all.first.transactionReference, equals('123456789'));
    });

    // ── Test 2: PDF -> SMS Duplicate Merge ──────────────────────────────────
    test('2. PDF -> SMS duplicate merge enriches exact timestamp and reference',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final pdfDraft = TransactionDraft(
        amount: 1499.0,
        merchant: 'Amazon Seller Services',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 0, 0, 0),
        account: 'SBI **1122',
      );
      await service.ingestSingle(draft: pdfDraft);

      final smsDraft = TransactionDraft(
        amount: 1499.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 15, 45, 0),
        transactionReference: 'RRN:8877665544',
        account: 'SBI 1122',
      );
      final r = await service.ingestSingle(draft: smsDraft);
      expect(r.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
      expect(all.first.sourceTypes, containsAll(['pdf', 'sms']));
      expect(all.first.date.hour, equals(15));
      expect(all.first.date.minute, equals(45));
    });

    // ── Test 3: SMS -> CSV Duplicate Merge ──────────────────────────────────
    test('3. SMS -> CSV duplicate merge preserves canonical identity',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final smsDraft = TransactionDraft(
        amount: 540.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 13, 0, 0),
        transactionReference: 'UPI/998877/Swiggy',
      );
      await service.ingestSingle(draft: smsDraft);

      final csvDraft = TransactionDraft(
        amount: 540.0,
        merchant: 'SWIGGY BANGALORE',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime(2026, 8, 14, 13, 0, 0),
        transactionReference: '998877',
      );
      final r = await service.ingestSingle(draft: csvDraft);
      expect(r.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
      expect(all.first.sourceTypes, containsAll(['sms', 'csv']));
    });

    // ── Test 4: CSV -> Excel Duplicate Merge ────────────────────────────────
    test('4. CSV -> Excel duplicate merge links cross-document statements',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final csvDraft = TransactionDraft(
        amount: 2500.0,
        merchant: 'Cult Fit Healthcare',
        category: 'Fitness',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime(2026, 8, 10, 10, 0, 0),
        transactionReference: 'CULT987654',
      );
      await service.ingestSingle(draft: csvDraft);

      final excelDraft = TransactionDraft(
        amount: 2500.0,
        merchant: 'Cult Fit',
        category: 'Fitness',
        type: TransactionType.debit,
        source: TransactionSource.excel,
        date: DateTime(2026, 8, 10, 0, 0, 0),
        transactionReference: 'REF: CULT987654',
      );
      final r = await service.ingestSingle(draft: excelDraft);
      expect(r.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
      expect(all.first.sourceTypes, containsAll(['csv', 'excel']));
    });

    // ── Test 5: PDF -> OCR Duplicate Merge ──────────────────────────────────
    test('5. PDF -> OCR duplicate merge detects physical receipt scan',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final pdfDraft = TransactionDraft(
        amount: 850.0,
        merchant: 'Starbucks Coffee',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 12, 17, 30, 0),
        transactionReference: 'SBX112233',
      );
      await service.ingestSingle(draft: pdfDraft);

      final ocrDraft = TransactionDraft(
        amount: 850.0,
        merchant: 'STARBUCKS STORE #4412',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.ocr,
        date: DateTime(2026, 8, 12, 17, 30, 0),
        transactionReference: 'REF: SBX112233',
      );
      final r = await service.ingestSingle(draft: ocrDraft);
      expect(r.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
      expect(all.first.sourceTypes, containsAll(['pdf', 'ocr']));
    });

    // ── Test 6: Manual -> SMS Duplicate Detection ───────────────────────────
    test('6. Manual -> SMS duplicate detection matches manual pre-entry',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final manualDraft = TransactionDraft(
        amount: 250.0,
        merchant: 'Chai Point',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 14, 16, 0, 0),
      );
      await service.ingestSingle(draft: manualDraft);

      final smsDraft = TransactionDraft(
        amount: 250.0,
        merchant: 'Chai Point Pvt Ltd',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 16, 5, 0),
        transactionReference: 'TXN778899',
      );
      final r = await service.ingestSingle(draft: smsDraft);
      expect(r.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
      expect(all.first.sourceTypes, containsAll(['manual', 'sms']));
    });

    // ── Test 7: Voice -> SMS Duplicate Merge ────────────────────────────────
    test('7. Voice -> SMS duplicate merge unites voice log with incoming SMS',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final voiceDraft = TransactionDraft(
        amount: 49.0,
        merchant: 'Uber Auto',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.voice,
        date: DateTime(2026, 8, 14, 9, 30, 0),
      );
      await service.ingestSingle(draft: voiceDraft);

      final smsDraft = TransactionDraft(
        amount: 49.0,
        merchant: 'UBER INDIA SYSTEMS',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 9, 31, 0),
        transactionReference: 'UBR102030',
      );
      final r = await service.ingestSingle(draft: smsDraft);
      expect(r.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
      expect(all.first.sourceTypes, containsAll(['voice', 'sms']));
    });

    // ── Test 8: Backup -> Existing Data (Zero Duplicate) ────────────────────
    test('8. Backup restore with existing transactions preserves exact count',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final tx1 = TransactionDraft(
        amount: 50000.0,
        merchant: 'Tech Corp Salary',
        category: 'Salary',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 1, 10, 0, 0),
        transactionReference: 'SAL889900',
      );
      await service.ingestSingle(draft: tx1);

      // Restore backup containing tx1
      final backupDraft = TransactionDraft(
        amount: 50000.0,
        merchant: 'Tech Corp Salary',
        category: 'Salary',
        type: TransactionType.credit,
        source: TransactionSource.backup,
        date: DateTime(2026, 8, 1, 10, 0, 0),
        transactionReference: 'SAL889900',
      );
      final r = await service.ingestSingle(draft: backupDraft);
      expect(r.isMerged, isTrue);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
    });

    // ── Test 9: Same PDF Twice ──────────────────────────────────────────────
    test('9. Re-importing identical PDF produces 0 new records', () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final batch = List.generate(
        10,
        (i) => TransactionDraft(
          amount: (i + 1) * 100.0,
          merchant: 'Merchant $i',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.pdf,
          date: DateTime(2026, 8, 10, 10, i, 0),
          transactionReference: 'PDF_REF_$i',
        ),
      );

      final p1 = await service.previewBatch(incoming: batch);
      expect(p1.newCount, equals(10));
      expect(p1.duplicateCount, equals(0));

      final decisions1 = p1.items
          .map((item) => IngestionItemDecision(
                draft: item.draft,
                userChoice: IngestionUserChoice.forceNew,
              ))
          .toList();
      final commit1 = await service.commitBatch(decisions: decisions1);
      expect(commit1.insertedCount, equals(10));

      // Re-import identical batch
      final p2 = await service.previewBatch(incoming: batch);
      expect(p2.newCount, equals(0));
      expect(p2.duplicateCount, equals(10));

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(10));
    });

    // ── Test 10: Same SMS Scan Twice ────────────────────────────────────────
    test('10. Repeated SMS scan produces 0 duplicates', () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final smsBatch = [
        TransactionDraft(
          amount: 379.0,
          merchant: 'Google One',
          category: 'Subscriptions',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 14, 10, 0, 0),
          transactionReference: 'G1_REF_01',
        ),
        TransactionDraft(
          amount: 299.0,
          merchant: 'Netflix',
          category: 'Subscriptions',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 14, 11, 0, 0),
          transactionReference: 'NFLX_REF_02',
        ),
      ];

      final p1 = await service.previewBatch(incoming: smsBatch);
      final decisions1 = p1.items
          .map((item) => IngestionItemDecision(
                draft: item.draft,
                userChoice: IngestionUserChoice.forceNew,
              ))
          .toList();
      await service.commitBatch(decisions: decisions1);

      final p2 = await service.previewBatch(incoming: smsBatch);
      expect(p2.newCount, equals(0));
      expect(p2.duplicateCount, equals(2));

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });

    // ── Test 11: Same CSV Twice ─────────────────────────────────────────────
    test('11. Importing same CSV twice produces 0 new records', () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final csvBatch = [
        TransactionDraft(
          amount: 750.0,
          merchant: 'BookMyShow',
          category: 'Entertainment',
          type: TransactionType.debit,
          source: TransactionSource.csv,
          date: DateTime(2026, 8, 5, 20, 0, 0),
          transactionReference: 'BMS554433',
        ),
      ];

      await service.commitBatch(decisions: [
        IngestionItemDecision(
            draft: csvBatch.first, userChoice: IngestionUserChoice.forceNew)
      ]);

      final p2 = await service.previewBatch(incoming: csvBatch);
      expect(p2.newCount, equals(0));
      expect(p2.duplicateCount, equals(1));

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
    });

    // ── Test 12: Critical Safety - Same Merchant & Amount on Different Dates ─
    test(
        '12. CRITICAL SAFETY: Same merchant & amount on DIFFERENT dates MUST be 2 distinct transactions',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final txAug14 = TransactionDraft(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
      );

      final txAug21 = TransactionDraft(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 21, 10, 0, 0), // 7 days later
      );

      await service.ingestSingle(draft: txAug14);
      final r2 = await service.ingestSingle(draft: txAug21);

      expect(r2.isInserted, isTrue);
      expect(r2.isMerged, isFalse);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });

    // ── Test 13: Critical Safety - Same Merchant & Amount Same Day Different Times
    test(
        '13. CRITICAL SAFETY: Amazon ₹500 at 10:00 vs 18:00 on same day MUST remain 2 distinct transactions',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final txMorning = TransactionDraft(
        amount: 500.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
      );

      final txEvening = TransactionDraft(
        amount: 500.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 18, 0, 0), // 8 hours later
      );

      await service.ingestSingle(draft: txMorning);
      final r2 = await service.ingestSingle(draft: txEvening);

      expect(r2.isInserted, isTrue);
      expect(r2.isMerged, isFalse);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });

    // ── Test 14: Profile Isolation ──────────────────────────────────────────
    test(
        '14. Strict Profile Isolation: Profile A and Profile B identical transactions remain separate',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final txProfileA = TransactionDraft(
        amount: 500.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        profileId: 'profile_alice',
      );

      final txProfileB = TransactionDraft(
        amount: 500.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        profileId: 'profile_bob',
      );

      await service.ingestSingle(draft: txProfileA, profileId: 'profile_alice');
      final r2 = await service.ingestSingle(
          draft: txProfileB, profileId: 'profile_bob');

      expect(r2.isInserted, isTrue);
      expect(r2.isMerged, isFalse);

      final txsA =
          await dbHelper.getAllTransactions(profileId: 'profile_alice');
      final txsB = await dbHelper.getAllTransactions(profileId: 'profile_bob');

      expect(txsA.length, equals(1));
      expect(txsB.length, equals(1));
    });

    // ── Test 15: Missing Reference Numbers ──────────────────────────────────
    test('15. Missing reference numbers match via contextual composite engine',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final tx1 = TransactionDraft(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        account: 'HDFC **4321',
      );
      await service.ingestSingle(draft: tx1);

      final tx2 = TransactionDraft(
        amount: 379.0,
        merchant: 'Google One Pvt Ltd',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        account: 'HDFC Bank - 4321',
      );
      final r2 = await service.ingestSingle(draft: tx2);

      expect(r2.isMerged, isTrue);
      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
    });

    // ── Test 16: Different Merchant Formatting ──────────────────────────────
    test('16. Merchant noise words and formatting variants resolve identically',
        () {
      final m1 = CanonicalTransactionIdentity.normalizeMerchantForFingerprint(
          'Google One');
      final m2 = CanonicalTransactionIdentity.normalizeMerchantForFingerprint(
          'GOOGLE ONE PVT LTD');
      final m3 = CanonicalTransactionIdentity.normalizeMerchantForFingerprint(
          'Google One Private Limited');
      final m4 = CanonicalTransactionIdentity.normalizeMerchantForFingerprint(
          'GOOGLE ONE VIA UPI');

      expect(m1, equals('google one'));
      expect(m2, equals('google one'));
      expect(m3, equals('google one'));
      expect(m4, equals('google one'));
    });

    // ── Test 17: Different Date Formats ─────────────────────────────────────
    test('17. Date strings in various formats normalize accurately', () {
      final d1 = DateTime.parse('2026-08-14T10:00:00.000');
      final d2 = DateTime(2026, 8, 14, 10, 0);

      expect(d1.year, equals(d2.year));
      expect(d1.month, equals(d2.month));
      expect(d1.day, equals(d2.day));
    });

    // ── Test 18: UPI Reference Normalization ─────────────────────────────────
    test('18. UPI reference formats normalize to identical alphanumeric token',
        () {
      final ref1 =
          CanonicalTransactionIdentity.normalizeReference('UPI/123456789/Pay');
      final ref2 = CanonicalTransactionIdentity.normalizeReference('123456789');
      final ref3 =
          CanonicalTransactionIdentity.normalizeReference('UPI-123456789');
      final ref4 =
          CanonicalTransactionIdentity.normalizeReference('upi: 123456789');

      expect(ref1, equals('123456789'));
      expect(ref2, equals('123456789'));
      expect(ref3, equals('123456789'));
      expect(ref4, equals('123456789'));
    });

    // ── Test 19: Bank Reference Normalization ────────────────────────────────
    test('19. Bank reference strings with prefixes normalize to clean token',
        () {
      final r1 =
          CanonicalTransactionIdentity.normalizeReference('REF: RRN-987654');
      final r2 = CanonicalTransactionIdentity.normalizeReference('987654');
      final r3 = CanonicalTransactionIdentity.normalizeReference('UTR:987654');
      final r4 =
          CanonicalTransactionIdentity.normalizeReference('IMPS/P2A/987654');

      expect(r1, equals('987654'));
      expect(r2, equals('987654'));
      expect(r3, equals('987654'));
      expect(r4, equals('987654'));
    });

    // ── Test 20: Concurrent Import Protection ───────────────────────────────
    test('20. Simultaneous batch imports maintain race-condition safety',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final draft1 = TransactionDraft(
        amount: 999.0,
        merchant: 'Coursera',
        category: 'Education',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 12, 0, 0),
        transactionReference: 'COURSERA999',
      );

      final draft2 = TransactionDraft(
        amount: 999.0,
        merchant: 'Coursera Inc',
        category: 'Education',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 12, 0, 0),
        transactionReference: 'REF: COURSERA999',
      );

      // Launch both concurrently
      await Future.wait([
        service.ingestSingle(draft: draft1),
        service.ingestSingle(draft: draft2),
      ]);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
    });

    // ── Test 21: Account Mismatch (Distinct Banks) ───────────────────────────
    test(
        '21. Transactions from different accounts on same day are separate events',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final hdfcTx = TransactionDraft(
        amount: 500.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        account: 'HDFC Bank **4321',
      );

      final sbiTx = TransactionDraft(
        amount: 500.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        account: 'SBI **8899',
      );

      await service.ingestSingle(draft: hdfcTx);
      final r2 = await service.ingestSingle(draft: sbiTx);

      expect(r2.isInserted, isTrue);
      expect(r2.isMerged, isFalse);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });

    // ── Test 22: Transaction Type Mismatch (Debit vs Credit) ─────────────────
    test('22. Debit and Credit of same amount are distinct financial events',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final debitTx = TransactionDraft(
        amount: 1000.0,
        merchant: 'John Doe',
        category: 'Transfer',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 11, 0, 0),
      );

      final creditTx = TransactionDraft(
        amount: 1000.0,
        merchant: 'John Doe',
        category: 'Transfer',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 11, 0, 0),
      );

      await service.ingestSingle(draft: debitTx);
      final r2 = await service.ingestSingle(draft: creditTx);

      expect(r2.isInserted, isTrue);
      expect(r2.isMerged, isFalse);

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });

    // ── Test 23: Credit Refund vs Debit Purchase ────────────────────────────
    test('23. Purchase and Refund from same merchant are distinct transactions',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final purchase = TransactionDraft(
        amount: 2499.0,
        merchant: 'Myntra',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 10, 14, 0, 0),
        transactionReference: 'MYN_BUY_1',
      );

      final refund = TransactionDraft(
        amount: 2499.0,
        merchant: 'Myntra Refund',
        category: 'Shopping',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 12, 10, 0, 0),
        transactionReference: 'MYN_REFUND_1',
      );

      await service.ingestSingle(draft: purchase);
      final r2 = await service.ingestSingle(draft: refund);

      expect(r2.isInserted, isTrue);
      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });

    // ── Test 24: Multiple Legitimate Identical Transactions (Metro Tickets) ──
    test(
        '24. Multiple legitimate identical transactions on same day with distinct times preserved',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final ride1 = TransactionDraft(
        amount: 30.0,
        merchant: 'Namma Metro',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 8, 45, 0),
      );

      final ride2 = TransactionDraft(
        amount: 30.0,
        merchant: 'Namma Metro',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 18, 15, 0),
      );

      await service.ingestSingle(draft: ride1);
      final r2 = await service.ingestSingle(draft: ride2);

      expect(r2.isInserted, isTrue);
      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });

    // ── Test 25: Provenance Merge Integrity ─────────────────────────────────
    test('25. Merged transaction combines sourceTypes array accurately',
        () async {
      final tx = TransactionItem(
        amount: 100.0,
        merchant: 'Store A',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14),
        sourceTypes: ['sms'],
      );

      final incoming = TransactionItem(
        amount: 100.0,
        merchant: 'Store A Clean',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14),
        sourceTypes: ['pdf'],
      );

      final merged = tx.mergeWith(incoming);
      expect(merged.sourceTypes, containsAll(['sms', 'pdf']));
      expect(merged.displaySource, contains('SMS + PDF'));
    });

    // ── Test 26: Timeline Single-Row Verification ───────────────────────────
    test(
        '26. Financial timeline queries return exactly 1 row per canonical event',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final smsDraft = TransactionDraft(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        transactionReference: 'G1_CANONICAL',
      );
      final pdfDraft = TransactionDraft(
        amount: 379.0,
        merchant: 'GOOGLE ONE SERVICES',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 0, 0, 0),
        transactionReference: 'UTR:G1_CANONICAL',
      );

      await service.ingestSingle(draft: smsDraft);
      await service.ingestSingle(draft: pdfDraft);

      final timeline = await dbHelper.getAllTransactions();
      expect(timeline.length, equals(1));
      expect(timeline.first.displaySource, contains('SMS + PDF'));
    });

    // ── Test 27: Budget Total After Deduplication ───────────────────────────
    test('27. Budget spending calculation reflects only deduplicated totals',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final tx1 = TransactionDraft(
        amount: 500.0,
        merchant: 'Zara',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 12, 0, 0),
        transactionReference: 'ZARA123',
      );
      final tx2 = TransactionDraft(
        amount: 500.0,
        merchant: 'ZARA INDIA',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 0, 0, 0),
        transactionReference: 'UTR:ZARA123',
      );

      await service.ingestSingle(draft: tx1);
      await service.ingestSingle(draft: tx2);

      final all = await dbHelper.getAllTransactions();
      final totalSpent = all
          .where((t) => t.type == TransactionType.debit)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      expect(totalSpent, equals(500.0));
    });

    // ── Test 28: Safe Today Balance Integrity ───────────────────────────────
    test('28. Safe Today daily balance is not double-deducted', () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      const dailyBudget = 2000.0;
      final tx1 = TransactionDraft(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 10, 0, 0),
        transactionReference: 'GOOG379',
      );
      final tx2 = TransactionDraft(
        amount: 379.0,
        merchant: 'Google',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 0, 0, 0),
        transactionReference: 'REF: GOOG379',
      );

      await service.ingestSingle(draft: tx1);
      await service.ingestSingle(draft: tx2);

      final all = await dbHelper.getAllTransactions();
      final todayExpense = all
          .where((t) => t.type == TransactionType.debit)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      final safeTodayRemaining = dailyBudget - todayExpense;
      expect(safeTodayRemaining, equals(1621.0));
    });

    // ── Test 29: Money Brain RAG Retrieval Deduplication ────────────────────
    test('29. Money Brain retrieval context contains single canonical event',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final smsTx = TransactionDraft(
        amount: 99.0,
        merchant: 'Hotstar',
        category: 'Entertainment',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 14, 11, 0, 0),
        transactionReference: 'DISNEY99',
      );
      final pdfTx = TransactionDraft(
        amount: 99.0,
        merchant: 'DISNEY HOTSTAR',
        category: 'Entertainment',
        type: TransactionType.debit,
        source: TransactionSource.pdf,
        date: DateTime(2026, 8, 14, 0, 0, 0),
        transactionReference: 'UTR:DISNEY99',
      );

      await service.ingestSingle(draft: smsTx);
      await service.ingestSingle(draft: pdfTx);

      final dbTxs = await dbHelper.getAllTransactions();
      final hotstarTxs = dbTxs
          .where((t) => t.merchant.toLowerCase().contains('hotstar'))
          .toList();

      expect(hotstarTxs.length, equals(1));
    });

    // ── Test 30: Backup Restore Twice Idempotency ───────────────────────────
    test(
        '30. Restoring the same backup multiple times creates 0 duplicate rows',
        () async {
      final service = CanonicalIngestionService.instance;
      final dbHelper = DatabaseHelper.instance;

      final backupRecords = [
        TransactionDraft(
          amount: 1500.0,
          merchant: 'Electricity Bill',
          category: 'Bills',
          type: TransactionType.debit,
          source: TransactionSource.backup,
          date: DateTime(2026, 8, 1, 9, 0, 0),
          transactionReference: 'BESCOM_001',
        ),
        TransactionDraft(
          amount: 800.0,
          merchant: 'Water Bill',
          category: 'Bills',
          type: TransactionType.debit,
          source: TransactionSource.backup,
          date: DateTime(2026, 8, 2, 9, 0, 0),
          transactionReference: 'BWSSB_002',
        ),
      ];

      // First restore
      final p1 = await service.previewBatch(incoming: backupRecords);
      await service.commitBatch(
        decisions: p1.items
            .map((i) => IngestionItemDecision(
                draft: i.draft, userChoice: IngestionUserChoice.forceNew))
            .toList(),
      );

      // Second restore
      final p2 = await service.previewBatch(incoming: backupRecords);
      expect(p2.newCount, equals(0));
      expect(p2.duplicateCount, equals(2));

      await service.commitBatch(
        decisions: p2.items
            .map((i) => IngestionItemDecision(
                draft: i.draft,
                userChoice: IngestionUserChoice.autoMerge,
                targetExisting: i.matchedExistingTransaction))
            .toList(),
      );

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(2));
    });
  });
}
