# `.ppbackup` Archive Container Schema Specification (v2.5)

## 1. Archive File Structure
The `.ppbackup` container is a structured ZIP file formatted as:
```
backup.ppbackup
│
├── manifest.json       (Unencrypted minimal header: Magic, Version, Created ISO8601)
├── manifest.sig        (HMAC signature for manifest integrity)
├── metadata.enc        (Encrypted metadata: Transaction count, Accounts, Goals)
├── database.enc        (AES-256-GCM encrypted versioned JSON database export)
├── checksum.sha256     (SHA-256 payload integrity digest)
└── signature.json      (AES-256-GCM authentication tag & random IV)
```

## 2. Zero Metadata Leakage
Transaction counts, account totals, and financial figures are stored exclusively inside `metadata.enc`. Unencrypted `manifest.json` exposes zero financial metrics.
