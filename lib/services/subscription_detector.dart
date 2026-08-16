import '../models/transaction.dart';
import '../models/subscription.dart';

class SubscriptionDetectorService {
  static const List<String> knownSubscriptionMerchants = [
    'netflix',
    'spotify',
    'hotstar',
    'google one',
    'chatgpt',
    'youtube premium',
    'amazon prime',
    'prime video',
    'apple',
    'icloud',
    'disney',
    'jio',
    'airtel',
    'vi',
    'hbo',
    'xbox',
    'playstation'
  ];

  static List<SubscriptionItem> detectSubscriptions(
      List<TransactionItem> transactions) {
    final Map<String, List<TransactionItem>> grouped = {};

    for (final tx in transactions) {
      if (tx.type != TransactionType.debit) continue;
      final mLower = tx.merchant.toLowerCase().trim();

      // Check if merchant matches known subscriptions or appears recurring
      bool isMatch =
          knownSubscriptionMerchants.any((sub) => mLower.contains(sub));

      if (isMatch) {
        grouped.putIfAbsent(mLower, () => []).add(tx);
      }
    }

    final List<SubscriptionItem> results = [];

    grouped.forEach((merchantKey, txList) {
      txList.sort((a, b) => b.date.compareTo(a.date)); // Sort newest first

      double total = 0;
      for (var t in txList) {
        total += t.amount;
      }
      double avg = total / txList.length;

      // Capitalize merchant name nicely
      final displayName = _formatMerchantTitle(txList.first.merchant);

      results.add(SubscriptionItem(
        merchant: displayName,
        averageAmount: avg,
        lastBillingDate: txList.first.date,
        occurrenceCount: txList.length,
        category: txList.first.category,
      ));
    });

    return results;
  }

  static String _formatMerchantTitle(String raw) {
    if (raw.isEmpty) return 'Subscription';
    return raw.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
