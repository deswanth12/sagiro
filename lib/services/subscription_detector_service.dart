import '../models/transaction.dart';

class DetectedSubscription {
  final String merchant;
  final double amount;
  final String category;
  final DateTime lastBillingDate;
  final DateTime nextBillingDate;
  final int daysUntilRenewal;
  final String iconEmoji;

  const DetectedSubscription({
    required this.merchant,
    required this.amount,
    required this.category,
    required this.lastBillingDate,
    required this.nextBillingDate,
    required this.daysUntilRenewal,
    required this.iconEmoji,
  });
}

class SubscriptionDetectorService {
  static const Map<String, String> knownSubscriptions = {
    'netflix': '🎬',
    'spotify': '🎵',
    'amazon prime': '📦',
    'prime': '📦',
    'hotstar': '📺',
    'youtube': '▶️',
    'google one': '☁️',
    'icloud': '☁️',
    'apple': '🍎',
    'swiggy one': '🍔',
    'zomato gold': '🍔',
    'cult.fit': '🏋️‍♂️',
    'gym': '🏋️‍♂️',
    'chatgpt': '🤖',
  };

  static List<DetectedSubscription> detectSubscriptions(
      List<TransactionItem> transactions) {
    final List<DetectedSubscription> results = [];
    final now = DateTime.now();

    for (final entry in knownSubscriptions.entries) {
      final key = entry.key;
      final matching = transactions
          .where(
            (t) =>
                t.merchant.toLowerCase().contains(key) ||
                (t.notes?.toLowerCase().contains(key) ?? false),
          )
          .toList();

      if (matching.isNotEmpty) {
        matching.sort((a, b) => b.date.compareTo(a.date));
        final last = matching.first;
        final nextDate = last.date.add(const Duration(days: 30));
        final daysUntil = nextDate.difference(now).inDays;

        results.add(
          DetectedSubscription(
            merchant:
                last.merchant.isNotEmpty ? last.merchant : key.toUpperCase(),
            amount: last.amount,
            category: 'Subscription',
            lastBillingDate: last.date,
            nextBillingDate: nextDate,
            daysUntilRenewal: daysUntil,
            iconEmoji: entry.value,
          ),
        );
      }
    }

    return results;
  }
}
