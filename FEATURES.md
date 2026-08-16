# FEATURES.md - PaisaPilot Master Product Requirements Specification (PRD v1.0)

## 🏆 Signature Feature: Daily Money Mission 🔥
- **Light Gamification Engine**: Presents users with a daily financial challenge to drive daily active engagement (DAU):
  - *"Spend less than ₹400 today."*
  - *"No food delivery (Swiggy / Zomato) today."*
  - *"Skip one unnecessary purchase."*
  - *"Stay within your fuel budget."*
- **Streak Tracker**: Earns daily streaks (`5 Day Streak 🔥`) upon completing challenges.

---

## 1. Core Modules

### 🏠 Dashboard
- Personalized greeting ("👋 Good Evening, Deshu")
- Today's, weekly, and monthly spending totals
- Remaining budget & **Today's safe spending limit** (`₹425/day`)
- Savings this month
- Top spending category & top merchant
- Financial Health Score (`87/100`) & Budget Risk Indicator (**Safe**, **Moderate**, **High Risk ⚠️**)
- **Daily Money Mission** gamification widget
- Quick Actions (`＋ Add Expense`, `📷 Scan SMS`, `📄 Import CSV`)

### 💳 Transaction Engine & 3-Way Ingestion
- Automatic bank SMS detection
- Manual transaction entry modal sheet
- CSV import & export
- Edit, delete, and duplicate transaction detection
- Transaction search, filter, and timeline

### 📱 SMS Engine
- Background & foreground inbox scan
- Bank & UPI detection (HDFC, SBI, ICICI, Axis, Kotak, PayTM, PhonePe)
- Amount (₹), merchant, date/time, and account last 4 digits (`XX4921`) extraction
- Filter out OTPs and promotional messages

### 🧠 Smart Categorization & Rules Engine
- Auto category detection using local rule-based state machine
- **Smart Rules learning**: Saves user category edits into SQLite `category_rules`
- 98% automatic categorization without cloud AI

### 🛒 Merchant Intelligence ("Where Your Money Went")
- Merchant profile, total spent (`₹8,250`), order count (`21 Orders`), Average Order Value (`₹392`), and spending frequency

### 🔄 Subscription Detector
- Recurring payment detection: Netflix, Spotify, Amazon Prime, Google One, Hotstar, ChatGPT, YouTube Premium
- Total monthly commitment card (`₹1,285/mo`)

---

## 2. Non-Functional Requirements (NFRs)

### Performance SLA Standards
- **App Startup**: `< 2.0 seconds`
- **SMS Transaction Parsing**: `< 200 ms`
- **Dashboard Frame Render**: `< 300 ms` at 60 FPS / 120 FPS

### Security & Privacy
- **100% Local On-Device Processing**: `0 Bytes Uploaded`
- **Zero Credentials Requested**: No bank passwords, PINs, or OTPs
- **Database Encryption**: Encrypted SQLite local database (`sqflite`)

### Compatibility
- Android 8.0+ (API 26+)
- Material 3 Design System
- Dark Obsidian Mode natively supported
