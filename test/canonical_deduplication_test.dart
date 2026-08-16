import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/models/canonical_transaction_identity.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/document_engine/duplicate/duplicate_hash_detector.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  setUp(() async {
    await resetTestDatabase();
  });

  group('Canonical Transaction Identity Tests', () {
    test('Identical fingerprint generated for phrasing variants of Google One',
        () {
      final tx1 = TransactionItem(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 10, 0, 0),
        profileId: 'default_profile',
      );

      final tx2 = TransactionItem(
        amount: 379.0,
        merchant: 'Google One Pvt Ltd',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 10, 2, 0), // Within 10-minute bucket
        profileId: 'default_profile',
      );

      final fp1 = CanonicalTransactionIdentity.computeFingerprint(tx1);
      final fp2 = CanonicalTransactionIdentity.computeFingerprint(tx2);

      expect(fp1, equals(fp2));
      expect(
          fp1,
          equals(
              'COMP|default_profile|any_acc|2026-08-04|10:00|379.00|debit|google one'));
    });

    test('Reference-based identity takes precedence over composite', () {
      final tx = TransactionItem(
        amount: 1250.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 14, 30, 0),
        transactionReference: 'UPI49201948201',
        profileId: 'default_profile',
      );

      final fp = CanonicalTransactionIdentity.computeFingerprint(tx);
      expect(fp,
          equals('REF|default_profile|any_acc|upi49201948201|1250.00|debit'));
    });

    test(
        'Legitimate different transactions on same day have distinct fingerprints',
        () {
      final txLunch = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 13, 0, 0),
        profileId: 'default_profile',
      );

      final txDinner = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 20, 30, 0),
        profileId: 'default_profile',
      );

      final fpLunch = CanonicalTransactionIdentity.computeFingerprint(txLunch);
      final fpDinner =
          CanonicalTransactionIdentity.computeFingerprint(txDinner);

      expect(fpLunch, isNot(equals(fpDinner)));
    });
  });

  group('Real-Device 4-Duplicate Google One Regression Tests', () {
    test('Inserting Google One 379 4 times produces EXACTLY 1 database row',
        () async {
      final dbHelper = DatabaseHelper.instance;

      final googleOneTx = TransactionItem(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 10, 0, 0),
        profileId: 'default_profile',
      );

      // Attempt 4 separate insertions
      final id1 = await dbHelper.insertTransaction(googleOneTx);
      final id2 = await dbHelper.insertTransaction(googleOneTx);
      final id3 = await dbHelper.insertTransaction(googleOneTx);
      final id4 = await dbHelper.insertTransaction(googleOneTx);

      expect(id1, isNotNull);
      expect(id2, equals(id1));
      expect(id3, equals(id1));
      expect(id4, equals(id1));

      final all =
          await dbHelper.getAllTransactions(profileId: 'default_profile');
      expect(all.length, equals(1));
      expect(all.first.merchant, equals('Google One'));
      expect(all.first.amount, equals(379.0));
    });

    test(
        'Batch insertion with intra-batch duplicate records inserts EXACTLY 1 row',
        () async {
      final dbHelper = DatabaseHelper.instance;

      final tx1 = TransactionItem(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 10, 0, 0),
      );

      final tx2 = TransactionItem(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 10, 0, 0),
      );

      final tx3 = TransactionItem(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 10, 0, 0),
      );

      final result = await dbHelper.insertTransactionBatch([tx1, tx2, tx3]);

      expect(result.insertedCount, equals(1));
      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(1));
    });
  });

  group('Scanner Idempotency & Repeated Ingestion Tests', () {
    test('Running batch insert 10 times produces identical database state',
        () async {
      final dbHelper = DatabaseHelper.instance;

      final batch = [
        TransactionItem(
          amount: 379.0,
          merchant: 'Google One',
          category: 'Subscriptions',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 4, 10, 0, 0),
        ),
        TransactionItem(
          amount: 450.0,
          merchant: 'Zomato',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 4, 13, 15, 0),
        ),
        TransactionItem(
          amount: 25000.0,
          merchant: 'Salary Account',
          category: 'Salary',
          type: TransactionType.credit,
          source: TransactionSource.sms,
          date: DateTime(2026, 8, 1, 9, 0, 0),
        ),
      ];

      // Run 1: 3 inserted
      final r1 = await dbHelper.insertTransactionBatch(batch);
      expect(r1.insertedCount, equals(3));

      // Run 2 to 10: 0 new inserted
      for (int i = 2; i <= 10; i++) {
        final r = await dbHelper.insertTransactionBatch(batch);
        expect(r.insertedCount, equals(0),
            reason: 'Run $i should insert 0 duplicates');
      }

      final all = await dbHelper.getAllTransactions();
      expect(all.length, equals(3));
    });
  });

  group('Existing Database Duplicate Cleanup Migration Tests', () {
    test(
        'cleanupExistingDuplicates removes exact duplicates and retains original',
        () async {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      expect(db, isNotNull);

      // Force raw insert of 4 duplicate rows without fingerprint
      await db!.execute('''
        INSERT INTO transactions (amount, merchant, category, type, source, date, profileId)
        VALUES (379.0, 'Google One', 'Subscriptions', 'debit', 'sms', '2026-08-04T10:00:00.000', 'default_profile')
      ''');
      await db.execute('''
        INSERT INTO transactions (amount, merchant, category, type, source, date, profileId)
        VALUES (379.0, 'Google One', 'Subscriptions', 'debit', 'sms', '2026-08-04T10:00:00.000', 'default_profile')
      ''');
      await db.execute('''
        INSERT INTO transactions (amount, merchant, category, type, source, date, profileId)
        VALUES (379.0, 'Google One', 'Subscriptions', 'debit', 'sms', '2026-08-04T10:00:00.000', 'default_profile')
      ''');
      await db.execute('''
        INSERT INTO transactions (amount, merchant, category, type, source, date, profileId)
        VALUES (379.0, 'Google One', 'Subscriptions', 'debit', 'sms', '2026-08-04T10:00:00.000', 'default_profile')
      ''');

      final rawCount = (await db.query('transactions')).length;
      expect(rawCount, equals(4));

      // Run cleanup migration
      final removed = await dbHelper.cleanupExistingDuplicates();
      expect(removed, equals(3));

      final remaining = await dbHelper.getAllTransactions();
      expect(remaining.length, equals(1));
      expect(remaining.first.merchant, equals('Google One'));
      expect(remaining.first.amount, equals(379.0));
      expect(remaining.first.transactionFingerprint, isNotNull);
    });
  });

  group('Document Engine & Parser Duplicate Hash Alignment', () {
    test('DuplicateHashDetector aligns with CanonicalTransactionIdentity', () {
      final tx = TransactionItem(
        amount: 379.0,
        merchant: 'Google One',
        category: 'Subscriptions',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 4, 10, 0, 0),
      );

      final isDup = DuplicateHashDetector.isDuplicate(
        candidate: tx,
        existingTransactions: [tx],
      );

      expect(isDup, isTrue);
    });
  });
}
