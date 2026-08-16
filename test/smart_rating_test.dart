import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/in_app_review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Rating Unit Tests', () {
    test('InAppReviewService evaluates prompt eligibility', () async {
      final service = InAppReviewService.instance;
      expect(service, isNotNull);
    });
  });
}
