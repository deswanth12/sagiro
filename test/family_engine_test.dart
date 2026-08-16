import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/family_engine/models/family_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Family Engine Unit Tests', () {
    test('FamilyMember instantiates with correct defaults', () {
      final member = FamilyMember(
        id: 'mem_1',
        name: 'Rahul',
        avatarEmoji: '👨',
        role: FamilyRole.adult,
        createdAt: DateTime(2026, 8, 13),
      );

      expect(member.id, equals('mem_1'));
      expect(member.name, equals('Rahul'));
      expect(member.role, equals(FamilyRole.adult));
    });

    test('FamilyBudget holds budget limit', () {
      const budget = FamilyBudget(
        id: 'b_1',
        familyId: 'fam_1',
        category: 'Groceries',
        limitAmount: 15000.0,
        memberContributions: {},
      );

      expect(budget.category, equals('Groceries'));
      expect(budget.limitAmount, equals(15000.0));
    });
  });
}
