import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/category_rule.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('CategoryRule Model Tests', () {
    test('Creates CategoryRule with default createdAt date', () {
      final rule = CategoryRule(keyword: 'SWIGGY', category: 'Food');

      expect(rule.keyword, equals('SWIGGY'));
      expect(rule.category, equals('Food'));
      expect(rule.createdAt, isNotNull);
    });

    test('Serializes to map and back correctly', () {
      final rule = CategoryRule(id: 1, keyword: 'PETROL', category: 'Fuel');
      final map = rule.toMap();
      final restored = CategoryRule.fromMap(map);

      expect(restored.id, equals(1));
      expect(restored.keyword, equals('petrol'));
      expect(restored.category, equals('Fuel'));
    });
  });
}
