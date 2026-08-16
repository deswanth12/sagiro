import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/notification_service.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Smart Financial Notification Service Unit Tests', () {
    test('NotificationService singleton initializes cleanly', () {
      final service = NotificationService.instance;
      expect(service, isNotNull);
    });

    test('Triggers local notifications without throwing exceptions', () async {
      await NotificationService.instance.showLocalNotification(
        id: 9999,
        title: 'Test Notification',
        body: 'Local notification test body',
        rationale: 'Unit test execution',
        categoryKey: 'notif_morning_plan',
      );
      expect(true, isTrue);
    });
  });
}
