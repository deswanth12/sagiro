class MonthRange {
  final DateTime startInclusive;
  final DateTime endExclusive;
  final int year;
  final int month;

  const MonthRange._({
    required this.startInclusive,
    required this.endExclusive,
    required this.year,
    required this.month,
  });

  /// Factory for a specific calendar year and month (1-12) in local time.
  factory MonthRange.forYearMonth(int year, int month) {
    final normalizedMonth = ((month - 1) % 12) + 1;
    final yearOffset = (month - 1) ~/ 12;
    final actualYear = year + yearOffset;

    final start = DateTime(actualYear, normalizedMonth, 1);
    final end = (normalizedMonth == 12)
        ? DateTime(actualYear + 1, 1, 1)
        : DateTime(actualYear, normalizedMonth + 1, 1);

    return MonthRange._(
      startInclusive: start,
      endExclusive: end,
      year: actualYear,
      month: normalizedMonth,
    );
  }

  /// Factory for the month containing the given [date].
  factory MonthRange.forDate(DateTime date) {
    final local = date.toLocal();
    return MonthRange.forYearMonth(local.year, local.month);
  }

  /// Factory for current month.
  factory MonthRange.current() {
    return MonthRange.forDate(DateTime.now());
  }

  /// Factory for previous month.
  factory MonthRange.previous() {
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    return MonthRange.forYearMonth(prevYear, prevMonth);
  }

  /// Checks if [date] falls strictly within [startInclusive] and [endExclusive].
  /// Evaluated using local calendar date.
  bool contains(DateTime date) {
    final local = date.toLocal();
    return !local.isBefore(startInclusive) && local.isBefore(endExclusive);
  }

  /// Total days in this month.
  int get daysInMonth {
    return endExclusive.difference(startInclusive).inDays;
  }

  /// Days remaining in this month from [currentDate] (inclusive of current day).
  int daysRemaining(DateTime currentDate) {
    final local = currentDate.toLocal();
    if (local.isBefore(startInclusive)) return daysInMonth;
    if (!local.isBefore(endExclusive)) return 1;
    return (daysInMonth - local.day) + 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthRange &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;

  @override
  String toString() =>
      'MonthRange($year-${month.toString().padLeft(2, "0")}: $startInclusive <= date < $endExclusive)';
}
