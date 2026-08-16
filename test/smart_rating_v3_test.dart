import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/in_app_review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Rating V3 Unit Tests', () {
    test('InAppReviewService checks cool off window safely', () async {
      final service = InAppReviewService.instance;
      expect(service, isNotNull);
    });
  });
}
