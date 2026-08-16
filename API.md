# API.md - PaisaPilot Service Interface & Future Sync API Contracts

Although PaisaPilot MVP is **100% local-first**, this document defines the service interfaces used internally and the future REST protocol for encrypted cloud backup.

---

## 🔌 Internal Dart Service Contracts

### 1. `SmsParser`
```dart
class SmsParser {
  static TransactionItem? parseSms(String body, String sender, {DateTime? smsDate});
}
```

### 2. `SmartRulesService`
```dart
class SmartRulesService {
  Future<String> matchCategory(String merchant, String rawText);
  Future<void> learnRule(String merchant, String newCategory);
}
```

### 3. `SubscriptionDetectorService`
```dart
class SubscriptionDetectorService {
  static List<SubscriptionItem> detectSubscriptions(List<TransactionItem> transactions);
}
```

### 4. `BudgetForecastService`
```dart
class BudgetForecastService {
  static BudgetForecast calculateForecast(List<TransactionItem> transactions, double monthlyBudget);
}
```

---

## 🌐 Future Expansion: Encrypted Backup API Protocol (Phase 4)

### Endpoint: `POST /api/v1/sync/backup`
- **Authentication**: Bearer JWT (Zero-Knowledge Auth)
- **Encryption**: AES-256-GCM encrypted payload on client side before upload.

```json
{
  "device_id": "anon-device-uuid-1234",
  "encrypted_payload": "BASE64_AES256_CIPHERTEXT",
  "schema_version": 1
}
```
