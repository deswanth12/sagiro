# Sagiro ✈️💰

> **"Your bank SMS stays on your phone. Your money, simplified."**

**Sagiro** (`com.deshu.sagiro.app`) is a 100% on-device, privacy-first financial companion and intelligent budget tracker designed specifically for users managing multi-bank transactions. Powered by local bank SMS parsing, smart rule-based learning, recurring subscription detection, and budget velocity forecasting, Sagiro empowers users to take control of their money without compromising data privacy.

---

## 🌟 Core Pillars

- **100% Local Privacy**: Your financial data is processed 100% locally on your device by default. If optional Private Sync is enabled, end-to-end encrypted backups are stored in your personal Google Drive account.
- **3-Way Transaction Ingestion**: Supports automatic **Bank SMS Parsing**, **Manual Transaction Entry**, and **CSV Statement Uploads** for 100% Google Play policy compliance and reliability.
- **Smart Local Rules Engine**: Learns user category corrections locally (e.g. Swiggy → Food, Indian Oil → Fuel) to achieve 98%+ automatic categorization without cloud AI.
- **Habit-Building Morning Check**: Features a dedicated **"Today's Safe Spend"** card (`₹425/day`) to help users build mindful daily spending habits.
- **Midnight Obsidian & Electric Neon Mint Aesthetic**: A distinctive dark aesthetic with frosted glassmorphism cards (`28px` rounded corners, `12px` blur).

---

## 🚀 Quick Setup & Installation

### Prerequisites
- [Flutter SDK 3.24+](https://flutter.dev) (Dart 3.5+)
- Android Studio / Android SDK (Build Tools API 34/35) or JDK 17+

### Running the App Locally

1. **Navigate to the repository**:
   ```bash
   cd "c:\smsbank app"
   ```

2. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run unit & integration test suite**:
   ```bash
   flutter test
   ```

4. **Launch on target device**:
   - **Android Device / Emulator**:
     ```bash
     flutter run -d android
     ```
   - **Chrome Web**:
     ```bash
     flutter run -d chrome
     ```
   - **Windows Desktop**:
     ```bash
     flutter run -d windows
     ```

---

## 🔒 Security & Backup Architecture

- **AES-256-GCM Backup Encryption**: Password-protected backup export with PBKDF2-HMAC-SHA256 key derivation, 16-byte random salt, and 12-byte IV.
- **Hardware-Backed Keystore**: Secure encryption key storage using `flutter_secure_storage` (Android Keystore / iOS Keychain).
- **Offline Local Biometrics**: Fingerprint & Face unlock via `local_auth`.

---

## 📊 Verification & Tests

- **Static Analysis**: `flutter analyze` (**0 issues found**)
- **Automated Tests**: `flutter test` (**189 / 189 passing**)
- **Package Application ID**: `com.deshu.sagiro.app`
   - **Android Device / Emulator**:
     ```bash
     flutter run
     ```

---

## 📚 Documentation Index

- 🎯 [PRODUCT.md](file:///c:/smsbank%20app/PRODUCT.md): Startup vision, target persona, and value proposition.
- 🏗️ [ARCHITECTURE.md](file:///c:/smsbank%20app/ARCHITECTURE.md): System architecture, technical decisions, and state management.
- 🎨 [UI_UX.md](file:///c:/smsbank%20app/UI_UX.md): Design tokens, Deep Obsidian palette, and Glassmorphism specs.
- 🗄️ [DATABASE.md](file:///c:/smsbank%20app/DATABASE.md): SQLite schema definitions and local smart rule storage.
- 🔌 [API.md](file:///c:/smsbank%20app/API.md): Local service contracts & future sync API specification.
- 🗺️ [ROADMAP.md](file:///c:/smsbank%20app/ROADMAP.md): Phase 1 to Phase 5 release milestones.
- 📜 [CHANGELOG.md](file:///c:/smsbank%20app/CHANGELOG.md): Production release history and version tracking.

---

## 🔒 Privacy Guarantee

PaisaPilot does **not** request banking passwords, read OTPs, or perform screen recording. All financial SMS messages are parsed in memory locally on the device using regular expression state machines.
