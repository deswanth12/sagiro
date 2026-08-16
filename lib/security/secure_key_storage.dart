import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// SecureKeyStorage — Safe Key Management backed by Android Keystore / iOS Keychain.
class SecureKeyStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _saltKey = 'paisapilot_sync_salt';
  static const String _recoveryKeyName = 'paisapilot_recovery_key';
  static const String _passphraseHashKey = 'paisapilot_passphrase_hash';

  /// DB key name — uniquely identifies the SQLCipher encryption key for the
  /// local Sagiro database. Must never change after first-write on a device.
  static const String _dbKeyName = 'sagiro_db_encryption_key';

  /// Save or Retrieve Salt.
  /// Salt is generated using [Random.secure()] — 32 bytes of CSPRNG output.
  /// This ensures PBKDF2 has full 256-bit salt entropy per NIST SP 800-132.
  static Future<Uint8List> getOrCreateSalt() async {
    final existing = await _storage.read(key: _saltKey);
    if (existing != null) {
      return base64Decode(existing);
    }
    // CRYPTO-01 FIX: Use Random.secure() instead of timestamp for full 256-bit entropy.
    final random = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }
    await _storage.write(key: _saltKey, value: base64Encode(bytes));
    return bytes;
  }

  /// Returns (or generates) the 256-bit SQLCipher database encryption key.
  ///
  /// Key lifecycle:
  /// - Generated once on first app launch using [Random.secure()] (CSPRNG).
  /// - Stored exclusively in Android Keystore / iOS Keychain via
  ///   [FlutterSecureStorage] with [AndroidOptions.encryptedSharedPreferences].
  /// - A 32-byte key is Base64-encoded → 44-char string passed to SQLCipher.
  ///
  /// Security properties:
  /// - Never stored on disk in plaintext; only in the OS secure enclave.
  /// - Survives app restarts; cleared on full app uninstall.
  /// - Finding 1 fix: satisfies THREAT_MODEL.md "AES-256 encrypted local storage".
  static Future<String> getOrCreateDatabaseKey() async {
    final existing = await _storage.read(key: _dbKeyName);
    if (existing != null) return existing;

    final random = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }
    final key = base64Encode(bytes); // 44-char base64 of 256-bit random key
    await _storage.write(key: _dbKeyName, value: key);
    return key;
  }

  /// Store Recovery Key
  static Future<void> saveRecoveryKey(String recoveryKey) async {
    await _storage.write(key: _recoveryKeyName, value: recoveryKey);
  }

  /// Read Recovery Key
  static Future<String?> getRecoveryKey() async {
    return await _storage.read(key: _recoveryKeyName);
  }

  /// Store Hashed Passphrase Verification
  static Future<void> savePassphraseHash(String hash) async {
    await _storage.write(key: _passphraseHashKey, value: hash);
  }

  /// Verify Passphrase Hash
  static Future<bool> verifyPassphraseHash(String hash) async {
    final stored = await _storage.read(key: _passphraseHashKey);
    return stored == hash;
  }
}
