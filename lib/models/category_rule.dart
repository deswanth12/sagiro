class CategoryRule {
  final int? id;
  final String keyword; // e.g. "Swiggy", "Indian Oil", "Amazon"
  final String category; // e.g. "Food", "Fuel", "Shopping"
  final DateTime createdAt;

  CategoryRule({
    this.id,
    required this.keyword,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyword': keyword.toLowerCase().trim(),
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CategoryRule.fromMap(Map<String, dynamic> map) {
    return CategoryRule(
      id: map['id'] as int?,
      keyword: map['keyword'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
