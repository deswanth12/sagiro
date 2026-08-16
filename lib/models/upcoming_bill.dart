class UpcomingBill {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String providerEmoji;
  final String category;
  final String account;
  final String frequency; // 'Monthly', 'Weekly', 'Yearly', 'Custom'
  final bool isActive;
  final bool isPaid;

  const UpcomingBill({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.providerEmoji,
    this.category = 'Housing',
    this.account = 'SBI',
    this.frequency = 'Monthly',
    this.isActive = true,
    this.isPaid = false,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  bool get isDueSoon =>
      isActive && !isPaid && daysRemaining >= 0 && daysRemaining <= 3;

  String get dueLabel {
    if (!isActive) return 'Paused';
    final days = daysRemaining;
    if (days == 0) return 'Due Today';
    if (days == 1) return 'Due Tomorrow';
    if (days > 1 && days <= 31) return 'Due ${dueDate.day}th';
    if (days < 0) return '${days.abs()}d Overdue';
    return 'Due ${dueDate.day}/${dueDate.month}';
  }

  String get frequencyLabel {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return '/ week';
      case 'biweekly':
        return '/ 2 weeks';
      case 'quarterly':
        return '/ quarter';
      case 'yearly':
        return '/ year';
      case 'custom':
        return '/ interval';
      case 'monthly':
      default:
        return '/ month';
    }
  }

  UpcomingBill copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? providerEmoji,
    String? category,
    String? account,
    String? frequency,
    bool? isActive,
    bool? isPaid,
  }) {
    return UpcomingBill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      providerEmoji: providerEmoji ?? this.providerEmoji,
      category: category ?? this.category,
      account: account ?? this.account,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'providerEmoji': providerEmoji,
        'category': category,
        'account': account,
        'frequency': frequency,
        'isActive': isActive ? 1 : 0,
        'isPaid': isPaid ? 1 : 0,
      };

  factory UpcomingBill.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['dueDate'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return UpcomingBill(
      id: map['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? 'Fixed Expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: parsedDate,
      providerEmoji: map['providerEmoji'] as String? ?? '🏠',
      category: map['category'] as String? ?? 'Housing',
      account: map['account'] as String? ?? 'SBI',
      frequency: map['frequency'] as String? ?? 'Monthly',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      isPaid: (map['isPaid'] as int? ?? 0) == 1,
    );
  }
}
