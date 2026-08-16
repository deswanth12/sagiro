# ARCHITECTURE.md - PaisaPilot Technical Architecture

## 🏛️ High-Level System Architecture

```
                    ┌─────────────────────────────────┐
                    │     Android BroadcastReceiver   │ (Bank SMS)
                    └────────────────┬────────────────┘
                                     │
┌─────────────────────────┐          │          ┌─────────────────────────┐
│     Manual Entry UI     ├──────────┼──────────┤     CSV File Importer   │
└─────────────────────────┘          │          └─────────────────────────┘
                                     ▼
                        ┌─────────────────────────┐
                        │   Smart Rules Engine    │ (Local Categorizer)
                        └────────────┬────────────┘
                                     │
                                     ▼
                        ┌─────────────────────────┐
                        │   SQLite Local Storage  │ (sqflite)
                        └────────────┬────────────┘
                                     │
                                     ▼
                        ┌─────────────────────────┐
                        │ BudgetProvider (State)  │
                        └────────────┬────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        ▼                            ▼                            ▼
┌──────────────┐             ┌──────────────┐             ┌──────────────┐
│  Dashboard   │             │   Insights   │             │   Budget     │
└──────────────┘             └──────────────┘             └──────────────┘
```

---

## 🛠️ Technology Stack & Rationale

- **Framework**: Flutter 3.24+ (Dart 3.5+) for cross-platform high performance and smooth 60fps animations.
- **Database**: SQLite (`sqflite`) for local transactional ACID persistence.
- **State Management**: `Provider` architecture (`ChangeNotifier`) for low-overhead reactive state propagation.
- **Charts Engine**: `fl_chart` for custom responsive pie charts and weekly spend bars.
- **Typography**: Google Fonts `Outfit`.

---

## 📂 Codebase Directory Structure

```
c:\smsbank app\
├── android/                   # Native Android manifest & SMS receiver config
├── lib/
│   ├── components/            # Reusable UI widgets (GlassCard, Heatmap, Modal)
│   ├── models/                # Data models (Transaction, Rule, Subscription, Forecast)
│   ├── providers/             # State management (BudgetProvider)
│   ├── services/              # Core logic engines (SMS Parser, Smart Rules, Forecast)
│   ├── theme/                 # Design tokens (AppTheme Obsidian & Electric Mint)
│   ├── views/                 # Navigation screens (Dashboard, Transactions, Budget, etc.)
│   └── main.dart              # Application entry point & MaterialApp config
├── test/                      # Automated unit test suites
├── ARCHITECTURE.md            # Technical decisions & architecture docs
├── DATABASE.md                # SQLite database schema docs
├── PRODUCT.md                 # Product strategy & vision docs
├── UI_UX.md                   # Design rules & component specs
└── README.md                  # Setup & quickstart guide
```
