import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Notification V4 Unit Tests', () {
    test('NotificationHistoryItem serializes to map cleanly', () {
      final item = NotificationHistoryItem(
        id: 2,
        title: 'Weekly Velocity Report',
        body: 'Spending velocity is on track.',
        timestamp: DateTime.now(),
        rationale: 'Weekly summary',
        categoryKey: 'notif_insights',
      );

      final map = item.toMap();
      expect(map['id'], equals(2));
      expect(map['categoryKey'], equals('notif_insights'));
    });
  });
}
