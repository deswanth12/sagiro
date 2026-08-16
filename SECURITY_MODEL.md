# PaisaPilot Security Model & Cryptographic Specification

## 1. Cryptographic Primitive Orchestration
- **Authenticated Encryption**: `AES-256-GCM` (128-bit authentication tag, 96-bit random IV).
- **Key Derivation Function**: `PBKDF2-HMAC-SHA256` (100,000 iterations, 32-byte output).
- **Integrity Digest**: `SHA-256` & `HMAC-SHA256` signatures.
- **Key Storage**: `flutter_secure_storage` with Android Keystore / iOS Keychain protection.

## 2. 24-Character Recovery Key System
Format: `AB9K-T72P-LX8Q-WM4R-ZC1H-K8VP` (6 groups of 4 characters using Base32 unambiguous charset). Provides high-entropy fallback for user device migration.

## 3. Secure File Sanitization
Temporary decrypted payload files are zero-overwritten before unlinking (`SecureDelete`), preventing residual flash memory inspection.
