import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sagiro/security/encryption_engine.dart';
import 'package:sagiro/services/private_sync_service.dart';
import 'package:sagiro/models/transaction.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'paisapilot_e2ee_salt': base64Encode(List<int>.filled(16, 7)),
    });
  });

  group('Private Sync™ Enterprise Security Unit Tests', () {
    test(
        'EncryptionEngine generates 24-character grouped Recovery Key correctly',
        () {
      final key = EncryptionEngine.generate24CharRecoveryKey();
      expect(key.length, 29); // 24 chars + 5 hyphens = 29
      final parts = key.split('-');
      expect(parts.length, 6);
      for (final p in parts) {
        expect(p.length, 4);
      }
    });

    test('EncryptionEngine AES-256-GCM encrypts and decrypts payload correctly',
        () {
      final key = EncryptionEngine.generateRandomBytes(32);
      final plaintext =
          Uint8List.fromList(utf8.encode('Secret Financial Data Hisari'));

      final encResult = EncryptionEngine.encryptAesGcm(plaintext, key);
      final decrypted = EncryptionEngine.decryptAesGcm(
          encResult.ciphertext, key, encResult.iv);

      expect(utf8.decode(decrypted), 'Secret Financial Data Hisari');
    });

    test(
        'EncryptionEngine SHA-256 and HMAC-SHA256 signatures compute accurately',
        () {
      final data = Uint8List.fromList(utf8.encode('Hisari Data'));
      final key = Uint8List.fromList(utf8.encode('secret_key'));

      final sha = EncryptionEngine.calculateSha256(data);
      final hmac = EncryptionEngine.calculateHmacSha256(data, key);

      expect(sha.length, 64);
      expect(hmac.length, 64);
    });

    test(
        'PrivateSyncService creates and restores structured E2EE .ppbackup archive cleanly',
        () async {
      final txns = [
        TransactionItem(
          merchant: 'Swiggy',
          amount: 450.0,
          type: TransactionType.debit,
          category: 'Food',
          date: DateTime.now(),
          source: TransactionSource.sms,
        ),
      ];

      final archiveBytes =
          await PrivateSyncService.createStructuredBackupArchive(
        transactions: txns,
        goalsCount: 2,
        passphrase: 'test_passphrase_123',
      );

      expect(archiveBytes.isNotEmpty, true);

      final restored = await PrivateSyncService.restoreFromBackupArchive(
        archiveBytes: archiveBytes,
        passphrase: 'test_passphrase_123',
      );

      expect(restored.length, 1);
      expect(restored.first.merchant, 'Swiggy');
      expect(restored.first.amount, 450.0);
    });

    test(
        'PrivateSyncService evaluateBackupHealth returns correct health scores',
        () {
      final freshHealth =
          PrivateSyncService.evaluateBackupHealth(DateTime.now());
      expect(freshHealth.healthScore, 100);
      expect(freshHealth.statusLabel.contains('Protected'), true);

      final oldHealth = PrivateSyncService.evaluateBackupHealth(
          DateTime.now().subtract(const Duration(days: 10)));
      expect(oldHealth.healthScore, 75);
      expect(oldHealth.statusLabel.contains('Due'), true);
    });
  });
}
