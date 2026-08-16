# Private Sync™ Restore Flow & Device Migration Wizard

## 1. Restore Sequence
```
Download Backup Archive (.ppbackup)
      │
      ▼
Verify HMAC Signature & AES-256-GCM Auth Tag
      │
      ▼
Decrypt Payload in Temporary Sandbox
      │
      ▼
Validate SHA-256 Checksum & Run Sequential Migration (v1 -> v2 -> v3)
      │
      ▼
Restore Simulation & Preview Card (User sees: Tx count, Accounts, Goals, Verified ✓)
      │
      ▼
Atomic Database Swap
      │
      ▼
Secure Delete: Overwrite Temporary Files with Zeroes + Memory Buffer Cleanup
```
