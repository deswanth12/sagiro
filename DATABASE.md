# DATABASE.md - PaisaPilot SQLite Schema Specification

## 🗄️ Database Name: `paisapilot.db` (SQLite 3)

---

## 1. Table: `transactions`

Stores all parsed bank SMS, manually entered, and CSV imported transactions.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Unique transaction ID |
| `amount` | `REAL` | `NOT NULL` | Transaction amount in INR (₹) |
| `merchant` | `TEXT` | `NOT NULL` | Extracted merchant / payee name |
| `category` | `TEXT` | `NOT NULL` | Category (Food, Fuel, Shopping, EMI, Rent, Medical, etc.) |
| `type` | `TEXT` | `NOT NULL` | `debit` or `credit` |
| `source` | `TEXT` | `NOT NULL` | `sms`, `manual`, or `csv` |
| `date` | `TEXT` | `NOT NULL` | ISO8601 string timestamp |
| `account` | `TEXT` | `NULLABLE` | Last 4 digits of bank account / card |
| `notes` | `TEXT` | `NULLABLE` | User custom notes |
| `rawSms` | `TEXT` | `NULLABLE` | Original SMS body when `source='sms'`. NULL for manual entries; for CSV imports stores filename |
| `splits` | `TEXT` | `NULLABLE` | JSON array string storing split categories and sub-amounts |

---

## 2. Table: `category_rules`

Stores 100% local smart learning rules for auto-categorization.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Rule ID |
| `keyword` | `TEXT` | `UNIQUE NOT NULL` | Lowercase merchant keyword (e.g., `swiggy`, `indian oil`) |
| `category` | `TEXT` | `NOT NULL` | Category mapping (e.g., `Food`, `Fuel`) |
| `createdAt` | `TEXT` | `NOT NULL` | ISO8601 creation timestamp |

---

## 3. Table: `settings`

Key-value store for app configuration and targets.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `key` | `TEXT` | `PRIMARY KEY` | Setting key (e.g. `monthly_budget`) |
| `value` | `TEXT` | `NOT NULL` | Setting value |

---

## 4. Table: `savings_goals`

Stores local target savings goals.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Unique goal ID |
| `title` | `TEXT` | `NOT NULL` | Goal title (e.g., Emergency Fund) |
| `targetAmount` | `REAL` | `NOT NULL` | Target amount in INR |
| `currentAmount` | `REAL` | `NOT NULL` | Saved amount so far |
| `targetDate` | `TEXT` | `NOT NULL` | ISO8601 target date |
| `emoji` | `TEXT` | `NOT NULL` | Visual emoji icon |

---

## 5. Table: `upcoming_bills`

Stores recurring/upcoming bills and subscriptions.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Unique bill ID |
| `title` | `TEXT` | `NOT NULL` | Bill title |
| `amount` | `REAL` | `NOT NULL` | Due amount |
| `dueDate` | `TEXT` | `NOT NULL` | ISO8601 due date |
| `providerEmoji` | `TEXT` | `NOT NULL` | Service icon / emoji |
| `isPaid` | `INTEGER` | `NOT NULL DEFAULT 0` | `1` if paid, `0` if pending |
