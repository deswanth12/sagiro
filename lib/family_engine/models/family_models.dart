enum FamilyRole { owner, adult, child, guest }

class FamilyMember {
  final String id;
  final String name;
  final String avatarEmoji;
  final FamilyRole role;
  final DateTime createdAt;
  final bool isActive;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive ? 1 : 0,
      };

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
        id: map['id'] as String? ?? 'default_profile',
        name: map['name'] as String? ?? 'Primary Account',
        avatarEmoji: map['avatarEmoji'] as String? ?? '👤',
        role: FamilyRole.values.firstWhere(
            (r) => r.name == (map['role'] as String?),
            orElse: () => FamilyRole.owner),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isActive: (map['isActive'] as int? ?? 1) == 1,
      );
}

class FamilyBudget {
  final String id;
  final String familyId;
  final String category;
  final double limitAmount;
  final Map<String, double> memberContributions;

  const FamilyBudget({
    required this.id,
    required this.familyId,
    required this.category,
    required this.limitAmount,
    required this.memberContributions,
  });

  double get totalSpent =>
      memberContributions.values.fold(0.0, (s, a) => s + a);
  double get remaining => (limitAmount - totalSpent).clamp(0.0, 999999.0);
}

class FamilyGoal {
  final String id;
  final String familyId;
  final String title;
  final double targetAmount;
  final Map<String, double> memberContributions;

  const FamilyGoal({
    required this.id,
    required this.familyId,
    required this.title,
    required this.targetAmount,
    required this.memberContributions,
  });

  double get totalSaved =>
      memberContributions.values.fold(0.0, (s, a) => s + a);
  double get progressPercentage => targetAmount > 0
      ? (totalSaved / targetAmount * 100).clamp(0.0, 100.0)
      : 0.0;
}

class ChildAllowance {
  final String childId;
  final String childName;
  final double monthlyAmount;
  final double spentAmount;

  const ChildAllowance({
    required this.childId,
    required this.childName,
    required this.monthlyAmount,
    required this.spentAmount,
  });

  double get remaining => (monthlyAmount - spentAmount).clamp(0.0, 999999.0);
}
