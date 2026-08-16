import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/backup_service.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/models/category_rule.dart';
import 'package:sagiro/services/database_helper.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('BackupService Engine Tests', () {
    setUp(() async {
      await DatabaseHelper.instance.clearAllData();
      await DatabaseHelper.instance.insertTransaction(
        TransactionItem(
          amount: 1500.0,
          merchant: 'Amazon',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(2026, 8, 1),
        ),
      );
      await DatabaseHelper.instance.insertRule(
        CategoryRule(keyword: 'amazon', category: 'Shopping'),
      );
    });

    test(
        'Generates valid .ppbackup JSON archive with SHA-256 integrity checksum',
        () async {
      final jsonStr = await BackupService.generateBackupArchive();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(map['metadata'], isNotNull);
      expect(map['checksum'], isNotNull);
      expect(map['payload'], isNotNull);
      expect(map['metadata']['appName'], equals('Sagiro'));
    });

    test('Validates backup header preview correctly', () async {
      final validJson = await BackupService.generateBackupArchive();
      final meta = BackupService.inspectBackupHeader(validJson);

      expect(meta.appName, equals('Sagiro'));
      expect(meta.transactionCount, equals(1));
    });

    test('Restores database state cleanly from valid backup archive', () async {
      final backupJson = await BackupService.generateBackupArchive();

      // Clear local database
      await DatabaseHelper.instance.clearAllData();
      final emptyTxs = await DatabaseHelper.instance.getAllTransactions();
      expect(emptyTxs, isEmpty);

      // Perform full restore
      await BackupService.restoreFromArchive(backupJson);

      final restoredTxs = await DatabaseHelper.instance.getAllTransactions();
      expect(restoredTxs.length, equals(1));
      expect(restoredTxs.first.merchant, equals('Amazon'));
    });

    test('Rejects corrupted or tampered backup archive during restore',
        () async {
      const corruptedJson =
          '{"metadata":{},"checksum":"BAD_CHECKSUM","payload":""}';

      expect(
        () async => await BackupService.restoreFromArchive(corruptedJson),
        throwsA(isA<BackupException>()),
      );
    });

    test('Encrypted backup restores with correct password', () async {
      final backupJson =
          await BackupService.generateBackupArchive(password: 'correct horse');

      await DatabaseHelper.instance.clearAllData();
      await BackupService.restoreFromArchive(
        backupJson,
        password: 'correct horse',
      );

      final restoredTxs = await DatabaseHelper.instance.getAllTransactions();
      expect(restoredTxs.length, equals(1));
      expect(restoredTxs.first.merchant, equals('Amazon'));
    });

    test('Encrypted backup rejects wrong password', () async {
      final backupJson =
          await BackupService.generateBackupArchive(password: 'correct horse');

      expect(
        () async => BackupService.restoreFromArchive(
          backupJson,
          password: 'wrong horse',
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('Encrypted backup rejects modified ciphertext', () async {
      final backupJson =
          await BackupService.generateBackupArchive(password: 'correct horse');
      final map = jsonDecode(backupJson) as Map<String, dynamic>;
      final payload = map['payload'] as Map<String, dynamic>;
      payload['ciphertext'] = '${payload['ciphertext']}A';

      expect(
        () async => BackupService.restoreFromArchive(
          jsonEncode(map),
          password: 'correct horse',
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('Encrypted backup rejects modified metadata', () async {
      final backupJson =
          await BackupService.generateBackupArchive(password: 'correct horse');
      final map = jsonDecode(backupJson) as Map<String, dynamic>;
      final metadata = map['metadata'] as Map<String, dynamic>;
      metadata['transactionCount'] = 999;

      expect(
        () async => BackupService.restoreFromArchive(
          jsonEncode(map),
          password: 'correct horse',
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('Encrypted backups use unique salt nonce and ciphertext', () async {
      const password = 'same password';
      final first = jsonDecode(await BackupService.generateBackupArchive(
        password: password,
      )) as Map<String, dynamic>;
      final second = jsonDecode(await BackupService.generateBackupArchive(
        password: password,
      )) as Map<String, dynamic>;

      final firstPayload = first['payload'] as Map<String, dynamic>;
      final secondPayload = second['payload'] as Map<String, dynamic>;

      expect(firstPayload['salt'], isNot(equals(secondPayload['salt'])));
      expect(firstPayload['nonce'], isNot(equals(secondPayload['nonce'])));
      expect(firstPayload['ciphertext'],
          isNot(equals(secondPayload['ciphertext'])));
      expect(jsonEncode(first), isNot(contains('Amazon')));
      expect(jsonEncode(first), isNot(contains('Secret SMS')));
    });
  });
}
