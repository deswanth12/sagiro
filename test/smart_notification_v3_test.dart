import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Notification V3 Unit Tests', () {
    test('NotificationHistoryItem holds title and body', () {
      final item = NotificationHistoryItem(
        id: 1,
        title: 'Safe Spend Alert',
        body: 'You have ₹850 remaining for today.',
        timestamp: DateTime.now(),
        rationale: 'Daily spend check',
        categoryKey: 'notif_budget',
      );

      expect(item.id, equals(1));
      expect(item.title, equals('Safe Spend Alert'));
      expect(item.categoryKey, equals('notif_budget'));
    });
  });
}
