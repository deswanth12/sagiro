class TimelineStoryEvent {
  final DateTime date;
  final String title;
  final String amountText;
  final String category;
  final String iconEmoji;

  const TimelineStoryEvent({
    required this.date,
    required this.title,
    required this.amountText,
    required this.category,
    required this.iconEmoji,
  });
}

class FinancialTimelineEngine {
  static List<TimelineStoryEvent> getChronologicalStory({
    List<dynamic>? transactions,
    List<dynamic>? upcomingBills,
  }) {
    if ((transactions == null || transactions.isEmpty) &&
        (upcomingBills == null || upcomingBills.isEmpty)) {
      return [];
    }

    final List<TimelineStoryEvent> events = [];
    if (upcomingBills != null) {
      for (final bill in upcomingBills) {
        if (bill.isActive == false) continue;
        events.add(TimelineStoryEvent(
          date: bill.dueDate ?? DateTime.now(),
          title: bill.title ?? 'Recurring Bill',
          amountText: '-₹${(bill.amount ?? 0).toStringAsFixed(0)}',
          category: bill.category ?? 'Bills',
          iconEmoji: bill.providerEmoji ?? '📄',
        ));
      }
    }

    if (transactions != null) {
      for (final tx in transactions) {
        final isCredit = tx.type?.toString().contains('credit') ?? false;
        events.add(TimelineStoryEvent(
          date: tx.date ?? DateTime.now(),
          title: tx.merchant ?? 'Transaction',
          amountText:
              '${isCredit ? '+' : '-'}₹${(tx.amount ?? 0).toStringAsFixed(0)}',
          category: tx.category ?? 'General',
          iconEmoji: isCredit ? '💰' : '💸',
        ));
      }
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  static String answerTimelineQuery(String query) {
    return 'Timeline insights are calculated from your actual stored transactions.';
  }
}
