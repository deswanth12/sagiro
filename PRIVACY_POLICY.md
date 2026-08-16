# Sagiro Privacy Policy

**Application**: Sagiro  
**Package Name**: `com.deshu.sagiro.app`  
**Effective Date**: August 16, 2026  
**Developer**: Deshanth  

---

## 1. Our Core Privacy Guarantee
Sagiro is built on a **100% on-device, privacy-first architecture**. All financial calculations, SMS transaction parsing, and budgeting analytics are executed entirely locally on your Android device.

We **never** upload, sell, rent, or share your financial data, transaction history, or SMS messages with any external servers, advertisers, credit agencies, or third parties.

---

## 2. Information We Process & How It Is Handled

### A. SMS Messages (`READ_SMS` / `RECEIVE_SMS`)
- **Strict On-Device Parsing**: Sagiro filters and reads only alphanumeric bank transactional SMS notifications (such as alerts from HDFC, SBI, ICICI, Axis, PNB, Bank of Baroda, and UPI apps).
- **Zero Server Upload**: Parsing logic and SQLite storage are 100% local.
- **No Personal Message Access**: OTPs, personal messages, and non-financial SMS are completely ignored and never stored.

### B. Account Information (Optional Google Sign-In)
- If you sign in via Google Authentication, we receive basic authentication metadata (name, email, profile picture) solely for account personalization and syncing with your own Google Drive.
- Anonymous/Guest mode is fully supported without requiring any account login.

### C. Voice & Receipt Entry (Optional)
- Voice commands are transcribed locally via standard on-device OS speech recognition.
- Receipt images and camera scans are processed on-device; zero raw images or audio recordings are uploaded to remote servers.

---

## 3. Cloud Backup & Private Sync™ (Google Drive E2EE)
- Backups are stored exclusively in your own private Google Drive `appDataFolder`.
- Backups are protected with end-to-end **AES-256-GCM encryption**. The developer and third parties have zero access to your backup files.

---

## 4. App Security & Biometric Protection
- **Biometric & Passcode Lock**: Option to secure access using your fingerprint, face unlock, or device screen PIN.
- **Balance Masking**: Balances can be masked on launch to prevent shoulder-surfing.

---

## 5. Data Deletion & User Rights
- You can permanently delete all transactions, budgets, and local data at any time via **Settings → Reset App Data**.
- Uninstalling the application immediately deletes the local database from your device.

---

## 6. Contact & Support
For any questions regarding this Privacy Policy, please contact:  
- **Email**: deshanth@sagiro.app (or developer contact on Google Play Console)  
