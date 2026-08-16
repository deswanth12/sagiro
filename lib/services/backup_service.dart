import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../family_engine/services/family_service.dart';
import '../security/encryption_engine.dart';
import 'app_settings_service.dart';
import 'database_helper.dart';
import '../rag/financial_ai_engine.dart';

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => message;
}

class BackupMetadata {
  final String appName;
  final String appVersion;
  final int databaseVersion;
  final String backupVersion;
  final DateTime createdDate;
  final int transactionCount;
  final int categoryRuleCount;
  final bool isEncrypted;

  BackupMetadata({
    required this.appName,
    required this.appVersion,
    required this.databaseVersion,
    required this.backupVersion,
    required this.createdDate,
    required this.transactionCount,
    required this.categoryRuleCount,
    required this.isEncrypted,
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'databaseVersion': databaseVersion,
      'backupVersion': backupVersion,
      'createdDate': createdDate.toIso8601String(),
      'transactionCount': transactionCount,
      'categoryRuleCount': categoryRuleCount,
      'isEncrypted': isEncrypted,
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      appName: map['appName'] as String? ?? 'Sagiro',
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      databaseVersion: map['databaseVersion'] as int? ?? 1,
      backupVersion: map['backupVersion'] as String? ?? '1.0',
      createdDate: DateTime.tryParse(map['createdDate'] as String? ?? '') ??
          DateTime.now(),
      transactionCount: map['transactionCount'] as int? ?? 0,
      categoryRuleCount: map['categoryRuleCount'] as int? ?? 0,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
    );
  }
}

class BackupService {
  static const String kBackupVersion = '1.0';
  static const String kEncryptedBackupVersion = '2.0';
  static const String kEncryptionAlgorithm = 'AES-256-GCM';
  static const String kKdf = 'PBKDF2-HMAC-SHA256';
  static const int kSaltLengthBytes = 16;

  static Future<String> generateBackupArchive({String? password}) async {
    final db = DatabaseHelper.instance;

    final txs = await db.getAllTransactions();
    final rules = await db.getAllRules();
    final settings = await db.getAllSettings();
    final profiles = await FamilyService.instance.getAllProfiles();

    final backupContent = {
      'transactions': txs.map((t) {
        final map = t.toMap();
        map.remove('rawSms');
        return map;
      }).toList(),
      'category_rules': rules.map((r) => r.toMap()).toList(),
      'profiles': profiles.map((p) => p.toMap()).toList(),
      'settings': settings,
    };

    final backupJsonRaw = jsonEncode(backupContent);
    final checksum = sha256.convert(utf8.encode(backupJsonRaw)).toString();
    final isEncrypted = password != null && password.trim().isNotEmpty;

    final now = DateTime.now();
    await AppSettingsService.instance.updateLastBackupTimestamp(now);

    final metadata = BackupMetadata(
      appName: 'Sagiro',
      appVersion: DatabaseHelper.currentAppVersion,
      databaseVersion: DatabaseHelper.currentDbVersion,
      backupVersion: isEncrypted ? kEncryptedBackupVersion : kBackupVersion,
      createdDate: now,
      transactionCount: txs.length,
      categoryRuleCount: rules.length,
      isEncrypted: isEncrypted,
    );

    final Object payload = isEncrypted
        ? _encryptPayload(
            dataJsonRaw: backupJsonRaw,
            metadata: metadata,
            checksum: checksum,
            password: password.trim(),
          )
        : backupJsonRaw;

    return jsonEncode({
      'metadata': metadata.toMap(),
      'checksum': checksum,
      'payload': payload,
    });
  }

  static BackupMetadata inspectBackupHeader(String archiveContent) {
    try {
      final bundle = jsonDecode(archiveContent) as Map<String, dynamic>;
      final metaMap = bundle['metadata'] as Map<String, dynamic>;
      return BackupMetadata.fromMap(metaMap);
    } catch (_) {
      throw const BackupException('Invalid or corrupted backup file format.');
    }
  }

  static Future<void> restoreFromArchive(
    String archiveContent, {
    String? password,
  }) async {
    final Map<String, dynamic> bundle;
    try {
      bundle = jsonDecode(archiveContent) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException(
          'Corrupted backup file: Invalid JSON format.');
    }

    final metaMap = bundle['metadata'] as Map<String, dynamic>?;
    final expectedChecksum = bundle['checksum'] as String?;
    final rawPayload = bundle['payload'];

    if (metaMap == null || expectedChecksum == null || rawPayload == null) {
      throw const BackupException(
          'Corrupted backup file: Missing header fields.');
    }

    final metadata = BackupMetadata.fromMap(metaMap);
    final String decryptedJson;

    if (metadata.isEncrypted) {
      if (password == null || password.trim().isEmpty) {
        throw const BackupException(
            'Password required to decrypt this backup.');
      }
      try {
        decryptedJson = _decryptPayload(
          rawPayload,
          password: password.trim(),
          expectedOuterMetadata: metadata,
          expectedChecksum: expectedChecksum,
        );
      } catch (_) {
        throw const BackupException(
            'Incorrect password. Failed to decrypt backup.');
      }
    } else if (rawPayload is String) {
      decryptedJson = rawPayload;
    } else {
      throw const BackupException('Corrupted backup file: Invalid payload.');
    }

    final actualChecksum =
        sha256.convert(utf8.encode(decryptedJson)).toString();
    if (actualChecksum != expectedChecksum) {
      throw const BackupException(
          'Corrupted backup file: Checksum verification failed.');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(decryptedJson) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Corrupted backup data payload.');
    }

    await DatabaseHelper.instance.restoreFullDatabaseTransaction(
      rawTransactions:
          (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      rawRules:
          (data['category_rules'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      rawProfiles:
          (data['profiles'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      rawSettings: (data['settings'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    FinancialAiEngine.invalidateCache();
  }

  static Map<String, dynamic> _encryptPayload({
    required String dataJsonRaw,
    required BackupMetadata metadata,
    required String checksum,
    required String password,
  }) {
    final salt = EncryptionEngine.generateRandomBytes(kSaltLengthBytes);
    final key = EncryptionEngine.deriveKey(password, salt);
    final plaintextEnvelope = jsonEncode({
      'metadata': metadata.toMap(),
      'checksum': checksum,
      'data': jsonDecode(dataJsonRaw),
    });
    final encrypted = EncryptionEngine.encryptAesGcm(
      Uint8List.fromList(utf8.encode(plaintextEnvelope)),
      key,
    );

    return {
      'version': kEncryptedBackupVersion,
      'algorithm': kEncryptionAlgorithm,
      'kdf': kKdf,
      'kdfIterations': EncryptionEngine.pbkdf2Iterations,
      'salt': base64.encode(salt),
      'nonce': base64.encode(encrypted.iv),
      'ciphertext': base64.encode(encrypted.ciphertext),
    };
  }

  static String _decryptPayload(
    Object? rawPayload, {
    required String password,
    required BackupMetadata expectedOuterMetadata,
    required String expectedChecksum,
  }) {
    if (rawPayload is! Map) {
      throw const BackupException('Corrupted backup file: Invalid payload.');
    }
    final payload = rawPayload.cast<String, dynamic>();
    if (payload['version'] != kEncryptedBackupVersion ||
        payload['algorithm'] != kEncryptionAlgorithm ||
        payload['kdf'] != kKdf) {
      throw const BackupException(
          'Unsupported encrypted backup format or algorithm.');
    }

    final salt = base64.decode(payload['salt'] as String? ?? '');
    final nonce = base64.decode(payload['nonce'] as String? ?? '');
    final ciphertext = base64.decode(payload['ciphertext'] as String? ?? '');
    final key = EncryptionEngine.deriveKey(password, Uint8List.fromList(salt));
    final plaintext = EncryptionEngine.decryptAesGcm(
      Uint8List.fromList(ciphertext),
      key,
      Uint8List.fromList(nonce),
    );

    final envelope = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    final innerMetadata = BackupMetadata.fromMap(
      (envelope['metadata'] as Map).cast<String, dynamic>(),
    );
    final innerChecksum = envelope['checksum'] as String?;
    final data = envelope['data'];

    if (innerChecksum != expectedChecksum ||
        jsonEncode(innerMetadata.toMap()) !=
            jsonEncode(expectedOuterMetadata.toMap())) {
      throw const BackupException(
          'Corrupted backup file: Authenticated metadata mismatch.');
    }

    final dataJson = jsonEncode(data);
    final actualChecksum = sha256.convert(utf8.encode(dataJson)).toString();
    if (actualChecksum != expectedChecksum) {
      throw const BackupException(
          'Corrupted backup file: Checksum verification failed.');
    }
    return dataJson;
  }
}
