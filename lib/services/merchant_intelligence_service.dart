import '../models/transaction.dart';
import '../models/merchant_stats.dart';

class MerchantIntelligenceService {
  /// Corporate & legal entity suffix stripper
  static final RegExp _legalSuffixRegex = RegExp(
    r'\b(?:pvt\s*ltd|private\s*limited|ltd|limited|llp|inc|corporation|corp|co|retail\s*pvt|india\s*pvt\s*ltd|india\s*limited)\b',
    caseSensitive: false,
  );

  /// Merchant Normalization Engine with Specific Service Preservation
  static String normalizeMerchant(String raw) {
    String clean = raw.trim();
    if (clean.isEmpty) return 'Bank Transaction';

    final lower = clean.toLowerCase();

    // 1. Specific Subscriptions & Biller Services (Check before generic parents)
    if (lower.contains('google one')) {
      return 'Google One';
    }
    if (lower.contains('youtube premium')) {
      return 'YouTube Premium';
    }
    if (lower.contains('google play') || lower.contains('gsuite')) {
      return 'Google Play';
    }
    if (lower.contains('amazon prime') || lower.contains('prime video')) {
      return 'Amazon Prime';
    }
    if (lower.contains('amazon pay')) {
      return 'Amazon Pay';
    }
    if (lower.contains('swiggy instamart')) {
      return 'Swiggy Instamart';
    }
    if (lower.contains('swiggy dineout')) {
      return 'Swiggy Dineout';
    }
    if (lower.contains('airtel xstream fiber') ||
        lower.contains('xstream fiber')) {
      return 'Airtel Xstream Fiber';
    }
    if (lower.contains('airtel xstream')) {
      return 'Airtel Xstream';
    }
    if (lower.contains('airtel broadband') || lower.contains('airtel fiber')) {
      return 'Airtel Broadband';
    }
    if (lower.contains('airtel dth')) {
      return 'Airtel DTH';
    }
    if (lower.contains('jio fiber') || lower.contains('jiofiber')) {
      return 'Jio Fiber';
    }
    if (lower.contains('disney+ hotstar') || lower.contains('hotstar')) {
      return 'Hotstar';
    }
    if (lower.contains('reliance digital')) {
      return 'Reliance Digital';
    }
    if (lower.contains('reliance fresh') || lower.contains('reliance smart')) {
      return 'Reliance Fresh';
    }
    if (lower.contains('reliance retail')) {
      return 'Reliance Retail';
    }

    // 2. ATM Cash Withdrawals with location preservation
    if (lower.startsWith('atm') ||
        lower.contains('atm wdl') ||
        lower.contains('atm withdrawal')) {
      final atmMatch = RegExp(r'atm\s+([A-Za-z0-9\s]+)', caseSensitive: false)
          .firstMatch(clean);
      if (atmMatch != null && atmMatch.group(1) != null) {
        final loc = _titleCase(atmMatch.group(1)!.trim());
        if (loc.isNotEmpty &&
            !loc.toLowerCase().contains('cash') &&
            !loc.toLowerCase().contains('wdl')) {
          return 'ATM $loc';
        }
      }
      return 'ATM Cash Withdrawal';
    }

    // 3. Major Indian E-Commerce, Food, Travel, & Utilities
    if (lower.contains('swiggy')) {
      return 'Swiggy';
    }
    if (lower.contains('zomato')) {
      return 'Zomato';
    }
    if (lower.contains('blinkit') || lower.contains('grofers')) {
      return 'Blinkit';
    }
    if (lower.contains('zepto')) {
      return 'Zepto';
    }
    if (lower.contains('bigbasket') || lower.contains('innovative retail')) {
      return 'BigBasket';
    }
    if (lower.contains('amazon') || lower.contains('amzn')) {
      return 'Amazon';
    }
    if (lower.contains('flipkart') || lower.contains('fkrt')) {
      return 'Flipkart';
    }
    if (lower.contains('myntra')) {
      return 'Myntra';
    }
    if (lower.contains('uber')) {
      return 'Uber';
    }
    if (lower.contains('ola') || lower.contains('ani tech')) {
      return 'Ola';
    }
    if (lower.contains('rapido')) {
      return 'Rapido';
    }
    if (lower.contains('netflix')) {
      return 'Netflix';
    }
    if (lower.contains('spotify')) {
      return 'Spotify';
    }
    if (lower.contains('chatgpt') || lower.contains('openai')) {
      return 'ChatGPT';
    }
    if (lower.contains('apple.com/bill') || lower.contains('apple services')) {
      return 'Apple Services';
    }
    if (lower.contains('bookmyshow')) {
      return 'BookMyShow';
    }
    if (lower.contains('irctc')) {
      return 'IRCTC';
    }
    if (lower.contains('indian oil') || lower.contains('ioc l')) {
      return 'Indian Oil';
    }
    if (lower.contains('hpcl') || lower.contains('hindustan petroleum')) {
      return 'HPCL';
    }
    if (lower.contains('bpcl') || lower.contains('bharat petroleum')) {
      return 'BPCL';
    }
    if (lower.contains('apollo pharmacy') || lower.contains('apollo')) {
      return 'Apollo Pharmacy';
    }
    if (lower.contains('pharmeasy')) {
      return 'PharmEasy';
    }
    if (lower.contains('zerodha')) {
      return 'Zerodha';
    }
    if (lower.contains('groww')) {
      return 'Groww';
    }
    if (lower.contains('upstox')) {
      return 'Upstox';
    }
    if (lower.contains('paytm')) {
      return 'Paytm';
    }
    if (lower.contains('phonepe')) {
      return 'PhonePe';
    }
    if (lower.contains('gpay') || lower.contains('google pay')) {
      return 'Google Pay';
    }
    if (lower.contains('salary credited') ||
        lower.contains('salary credit') ||
        lower.contains('salary deposit') ||
        lower == 'salary') {
      return 'Salary Credit';
    }
    if (lower.contains('interest credit') ||
        lower.contains('interest credited') ||
        lower.contains('interest deposit') ||
        lower == 'interest') {
      return 'Interest Credit';
    }
    if (RegExp(r'\bcred\b').hasMatch(lower) ||
        lower.contains('cred club') ||
        lower.contains('dreamplug')) {
      return 'CRED';
    }
    if (lower.contains('jiomart') || lower.contains('reliance')) {
      return 'Reliance';
    }

    // 4. VPA cleaning (e.g. abc@okhdfcbank -> Abc, rahul@paytm -> Rahul)
    if (clean.contains('@')) {
      final handle = clean.split('@').first.trim();
      if (handle.isNotEmpty && handle.length > 2) {
        return _titleCase(handle.replaceAll(RegExp(r'[._\-]'), ' '));
      }
    }

    // 5. Indian Bank Transfer Narration cleaner (SBI, HDFC, ICICI, etc.)
    // Matches: "Dep Tfr 904235802338 K Lalitha Sbin Kuchi.lali Pa 0097735162098 At 70649 M.r. Palli Branch, Tirupati"
    // Matches: "Wdl Tfr 310205268626 Chelluru S Bin Chellurupr Paym 0097693162093 At 70649 M.r. Palli Branch, Tirupati"
    // Matches: "Wdl Tfr 657645714592 Mrs Chel Yesb Q750416041 0097692162094 At 70649 M.r. Palli Branch, Tirupati 34"
    if (lower.contains('dep tfr') ||
        lower.contains('wdl tfr') ||
        lower.contains('transfer to') ||
        lower.contains('transfer from') ||
        lower.contains('by transfer') ||
        lower.contains('to transfer')) {
      final transferMatch = RegExp(
        r'(?:dep|wdl|by|to)?\s*(?:tfr|transfer)?\s*(?:\d{8,})?\s*([A-Za-z\s.\x27&]{2,30}?)(?:\s+(?:sbin|yesb|hdfc|icici|axis|kotak|pnb|canara|bob|bin|paym|pa|kuchi|\d{6,}|at\s+\d+|branch)|\b|$)',
        caseSensitive: false,
      ).firstMatch(clean);

      if (transferMatch != null && transferMatch.group(1) != null) {
        String extracted = transferMatch.group(1)!.trim();
        extracted = extracted
            .replaceAll(
                RegExp(r'\b(?:tfr|dep|wdl|at|by|to|sbin|bin|pa|m\.?r\.?)\b',
                    caseSensitive: false),
                '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (extracted.length >= 3 && !RegExp(r'^\d+$').hasMatch(extracted)) {
          return _titleCase(extracted);
        }
      }
    }

    // 6. General cleaning & title casing for other merchants
    String stripped = clean.replaceAll(_legalSuffixRegex, '').trim();
    // Strip trailing branch locations or bank codes
    stripped = stripped.replaceAll(
        RegExp(r'(?:at\s+\d+|branch|\b\d{6,}\b).*$', caseSensitive: false), '');
    stripped = stripped
        .replaceAll(RegExp(r'[#\*\-_/]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (stripped.isEmpty || stripped.length < 2) {
      return 'Bank Transfer';
    }

    return _titleCase(stripped);
  }

  static const Set<String> _uppercaseAcronyms = {
    'hdfc',
    'icici',
    'sbi',
    'atm',
    'upi',
    'vpa',
    'irctc',
    'hpcl',
    'bpcl',
    'neft',
    'imps',
    'rtgs',
    'pos',
    'pnb',
    'bob',
    'axis',
    'kotak',
    'idbi',
    'rbi'
  };

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      if (_uppercaseAcronyms.contains(lower)) {
        return lower.toUpperCase();
      }
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static List<MerchantStats> getTopMerchants(List<TransactionItem> transactions,
      {int limit = 10}) {
    final Map<String, List<TransactionItem>> grouped = {};

    for (final tx in transactions) {
      if (tx.type != TransactionType.debit) continue;
      final normalized = normalizeMerchant(tx.merchant);
      final key = normalized.toLowerCase();
      if (key.isEmpty || key == 'bank transaction') continue;
      grouped.putIfAbsent(key, () => []).add(tx.copyWith(merchant: normalized));
    }

    final List<MerchantStats> statsList = [];

    grouped.forEach((key, txList) {
      txList.sort((a, b) => b.date.compareTo(a.date));
      final totalSpent =
          txList.fold<double>(0.0, (sum, item) => sum + item.amount);
      final count = txList.length;
      final avg = totalSpent / count;
      final displayName = txList.first.merchant;
      final cat = txList.first.category;

      statsList.add(MerchantStats(
        merchant: displayName,
        totalSpent: totalSpent,
        orderCount: count,
        averageOrderValue: avg,
        primaryCategory: cat,
        lastTransactionDate: txList.first.date,
      ));
    });

    statsList.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return statsList.take(limit).toList();
  }
}
