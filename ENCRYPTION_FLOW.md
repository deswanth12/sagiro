# Private Sync™ Encryption Flow Architecture

## 1. Encryption Sequence
```
Local SQLite Data ➔ JSON Export ➔ GZip Compression ➔ AES-256-GCM Encrypt ➔ HMAC Signature ➔ Container Zip
```

## 2. Parameter Specifications
- AES Key Size: 256 bits (derived via PBKDF2 with 100,000 iterations).
- Initialization Vector: 96 bits (randomly generated per encryption).
- Auth Tag: 128 bits.
