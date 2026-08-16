# Private Sync™ System Architecture Specification (v2.5)

> **"Private Sync™ — Encrypted. Private. Verified. Only You Can Unlock It."**

## 1. System Overview
PaisaPilot **Private Sync™** is an offline-first, zero-cloud-trust, End-to-End Encrypted (E2EE) backup, recovery, and synchronization system using the user's personal Google Drive restricted `appDataFolder`.

## 2. Component Pipeline
```
SQLite Local DB
      │
      ▼
Serialization to Versioned JSON Schema (v1)
      │
      ▼
GZip Payload Compression
      │
      ▼
AES-256-GCM Authenticated Encryption (Key derived via PBKDF2-HMAC-SHA256)
      │
      ▼
Packaging into Structured ZIP Container (.ppbackup)
      │
      ▼
Upload to User's Personal Google Drive (appDataFolder)
```

## 3. Storage Isolation
Backups are stored exclusively inside Google Drive's restricted `appDataFolder`. Backups are invisible in standard Drive file listings, eliminating accidental deletion risk.

## 4. Key Guarantees
- 0 Bytes Uploaded in Plaintext.
- Zero Cloud Key Knowledge (Keys stored in Android Keystore / iOS Keychain).
- Automated Integrity Checksums (SHA-256) & HMAC Signature verification.
