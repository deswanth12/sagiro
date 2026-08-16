import '../models/transaction.dart';

class ParsedVoiceExpense {
  final double amount;
  final String category;
  final String merchant;
  final TransactionType type;
  final String rawTranscript;
  final double confidenceScore;
  final String categoryEmoji;

  const ParsedVoiceExpense({
    required this.amount,
    required this.category,
    required this.merchant,
    required this.type,
    required this.rawTranscript,
    required this.confidenceScore,
    required this.categoryEmoji,
  });
}

class VoiceExpenseService {
  /// Parses natural spoken text into structured expense/income fields completely offline
  static ParsedVoiceExpense parseVoiceTranscript(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.isEmpty) {
      return const ParsedVoiceExpense(
        amount: 0.0,
        category: 'General',
        merchant: 'Expense',
        type: TransactionType.debit,
        rawTranscript: '',
        confidenceScore: 0.0,
        categoryEmoji: '💳',
      );
    }

    // 1. Determine Transaction Type (credit vs debit)
    TransactionType type = TransactionType.debit;
    if (lower.contains('received') ||
        lower.contains('credited') ||
        lower.contains('got') ||
        lower.contains('salary') ||
        lower.contains('cashback') ||
        lower.contains('refund') ||
        lower.contains('income') ||
        lower.contains('bonus')) {
      type = TransactionType.credit;
    }

    // 2. Extract Amount (matches ₹450, 450 rs, rupees 450, or standalone numbers like 450)
    final amountRegex = RegExp(
        r'(?:₹|rs\.?|rupees)?\s*(\d+(?:,\d+)*(?:\.\d+)?)\s*(?:rupees|rs)?',
        caseSensitive: false);
    double amount = 0.0;

    for (final match in amountRegex.allMatches(lower)) {
      final rawNum = match.group(1)?.replaceAll(',', '');
      if (rawNum != null) {
        final val = double.tryParse(rawNum) ?? 0.0;
        if (val > 0) {
          amount = val;
          break;
        }
      }
    }

    // 3. Check for Known Brands first
    String merchant = '';
    String category = 'General';
    String emoji = '💳';

    if (type == TransactionType.credit) {
      category = 'Income';
      emoji = '💰';
      if (lower.contains('salary')) {
        merchant = 'Salary Credit';
      } else if (lower.contains('cashback')) {
        merchant = 'Cashback Reward';
      } else if (lower.contains('refund')) {
        merchant = 'Refund Processed';
      }
    }

    if (merchant.isEmpty) {
      if (lower.contains('swiggy')) {
        merchant = 'Swiggy';
        category = 'Food & Dining';
        emoji = '🍔';
      } else if (lower.contains('zomato')) {
        merchant = 'Zomato';
        category = 'Food & Dining';
        emoji = '🍔';
      } else if (lower.contains('blinkit')) {
        merchant = 'Blinkit';
        category = 'Groceries';
        emoji = '🛒';
      } else if (lower.contains('zepto')) {
        merchant = 'Zepto';
        category = 'Groceries';
        emoji = '🛒';
      } else if (lower.contains('uber')) {
        merchant = 'Uber';
        category = 'Transportation';
        emoji = '🚗';
      } else if (lower.contains('ola')) {
        merchant = 'Ola';
        category = 'Transportation';
        emoji = '🚗';
      } else if (lower.contains('amazon')) {
        merchant = 'Amazon';
        category = 'Shopping';
        emoji = '🛍';
      } else if (lower.contains('flipkart')) {
        merchant = 'Flipkart';
        category = 'Shopping';
        emoji = '🛍';
      } else if (lower.contains('netflix')) {
        merchant = 'Netflix';
        category = 'Entertainment';
        emoji = '🎬';
      }
    }

    // 4. Fallback Preposition Matcher if no known brand found
    if (merchant.isEmpty) {
      final merchantRegex = RegExp(
          r'(?:at|on|from|to|for)\s+([a-z0-9\s]+?)(?:\s+(?:for|on|at|rs|rupees|\d+)|$)',
          caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(lower);
      if (merchantMatch != null) {
        final candidate = merchantMatch.group(1)?.trim();
        if (candidate != null &&
            candidate.isNotEmpty &&
            !candidate.contains(RegExp(r'^\d+$'))) {
          merchant = candidate
              .split(' ')
              .map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
              .join(' ');
        }
      }
    }

    // 5. Category Classification if not assigned by brand
    if (category == 'General') {
      if (lower.contains('food') ||
          lower.contains('lunch') ||
          lower.contains('dinner') ||
          lower.contains('restaurant') ||
          lower.contains('coffee') ||
          lower.contains('tea') ||
          lower.contains('cafe') ||
          lower.contains('snack') ||
          lower.contains('pizza') ||
          lower.contains('burger')) {
        category = 'Food & Dining';
        emoji = '🍔';
        if (merchant.isEmpty) merchant = 'Dining / Cafe';
      } else if (lower.contains('grocery') ||
          lower.contains('groceries') ||
          lower.contains('milk') ||
          lower.contains('supermarket') ||
          lower.contains('bigbasket') ||
          lower.contains('vegetables') ||
          lower.contains('fruits')) {
        category = 'Groceries';
        emoji = '🛒';
        if (merchant.isEmpty) merchant = 'Supermarket';
      } else if (lower.contains('rapido') ||
          lower.contains('cab') ||
          lower.contains('petrol') ||
          lower.contains('fuel') ||
          lower.contains('auto') ||
          lower.contains('bus') ||
          lower.contains('train') ||
          lower.contains('flight')) {
        category = 'Transportation';
        emoji = '🚗';
        if (merchant.isEmpty) merchant = 'Fuel Station';
      } else if (lower.contains('bill') ||
          lower.contains('electricity') ||
          lower.contains('water') ||
          lower.contains('wifi') ||
          lower.contains('internet') ||
          lower.contains('recharge') ||
          lower.contains('mobile') ||
          lower.contains('rent')) {
        category = 'Bills & Utilities';
        emoji = '⚡';
        if (merchant.isEmpty) {
          if (lower.contains('electricity')) {
            merchant = 'Electricity Bill';
          } else if (lower.contains('water')) {
            merchant = 'Water Bill';
          } else if (lower.contains('wifi') || lower.contains('internet')) {
            merchant = 'Internet Bill';
          } else {
            merchant = 'Utility Provider';
          }
        }
      } else if (lower.contains('saving') || lower.contains('savings')) {
        category = 'Savings';
        emoji = '💎';
        if (merchant.isEmpty) merchant = 'Savings Deposit';
      } else if (lower.contains('shopping') ||
          lower.contains('clothes') ||
          lower.contains('shoes') ||
          lower.contains('myntra')) {
        category = 'Shopping';
        emoji = '🛍';
        if (merchant.isEmpty) merchant = 'Retail Store';
      } else if (lower.contains('movie') ||
          lower.contains('cinema') ||
          lower.contains('prime') ||
          lower.contains('game') ||
          lower.contains('entertainment')) {
        category = 'Entertainment';
        emoji = '🎬';
        if (merchant.isEmpty) merchant = 'Entertainment';
      } else if (lower.contains('doctor') ||
          lower.contains('medicine') ||
          lower.contains('hospital') ||
          lower.contains('pharmacy') ||
          lower.contains('medical')) {
        category = 'Health & Medical';
        emoji = '🏥';
        if (merchant.isEmpty) merchant = 'Pharmacy / Health';
      }
    }

    if (merchant.isEmpty) {
      merchant = type == TransactionType.credit ? 'Income' : 'Voice Entry';
    }

    return ParsedVoiceExpense(
      amount: amount,
      category: category,
      merchant: merchant,
      type: type,
      rawTranscript: text,
      confidenceScore: amount > 0 ? 0.95 : 0.30,
      categoryEmoji: emoji,
    );
  }
}
