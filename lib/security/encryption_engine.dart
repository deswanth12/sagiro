import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// EncryptionEngine — Standard Cryptographic Orchestrator.
/// Orchestrates standard, audited algorithms:
/// - Authenticated Encryption: AES-256-GCM (128-bit tag, 96-bit IV)
/// - Key Derivation: PBKDF2-HMAC-SHA256 (100,000 iterations)
/// - Signature / Digest: HMAC-SHA256 & SHA-256
/// - Key Generator: 24-character grouped Recovery Key (e.g. AB9K-T72P-LX8Q-WM4R-ZC1H-K8VP)
class EncryptionEngine {
  static const int pbkdf2Iterations = 100000;
  static const int keyLengthBytes = 32; // 256 bits
  static const int ivLengthBytes = 12; // 96 bits for GCM
  static const int tagLengthBits = 128; // 128-bit auth tag

  /// Generates a random 24-character Recovery Key formatted in 4-char groups
  static String generate24CharRecoveryKey() {
    const chars =
        '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // Base32 unambiguous charset
    final random = Random.secure();
    final List<String> groups = [];

    for (int i = 0; i < 6; i++) {
      final String group = String.fromCharCodes(
        Iterable.generate(
            4, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
      groups.add(group);
    }
    return groups.join('-');
  }

  /// Generates cryptographically secure random bytes
  static Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derives a 256-bit AES key from a passphrase using PBKDF2-HMAC-SHA256
  static Uint8List deriveKey(String passphrase, Uint8List salt) {
    final pkcs39 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, pbkdf2Iterations, keyLengthBytes));
    return pkcs39.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  /// Calculates SHA-256 Digest of data bytes
  static String calculateSha256(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Calculates HMAC-SHA256 Signature for Manifest Integrity
  static String calculateHmacSha256(Uint8List data, Uint8List key) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).toString();
  }

  /// Encrypts plaintext bytes using AES-256-GCM
  static GcmEncryptionResult encryptAesGcm(Uint8List plaintext, Uint8List key) {
    final iv = generateRandomBytes(ivLengthBytes);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true,
          AEADParameters(KeyParameter(key), tagLengthBits, iv, Uint8List(0)));

    final cipherTextWithTag = cipher.process(plaintext);
    return GcmEncryptionResult(
      ciphertext: cipherTextWithTag,
      iv: iv,
    );
  }

  /// Decrypts ciphertext bytes using AES-256-GCM and verifies auth tag
  static Uint8List decryptAesGcm(
      Uint8List ciphertextWithTag, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false,
          AEADParameters(KeyParameter(key), tagLengthBits, iv, Uint8List(0)));

    return cipher.process(ciphertextWithTag);
  }
}

class GcmEncryptionResult {
  final Uint8List ciphertext;
  final Uint8List iv;

  GcmEncryptionResult({required this.ciphertext, required this.iv});
}
