import '../models/transaction.dart';
import '../account_engine/models/account_model.dart';
import '../models/savings_goal.dart';

class MerchantSearchResult {
  final String merchantName;
  final int transactionCount;
  final double totalSpend;
  final List<TransactionItem> transactions;

  MerchantSearchResult({
    required this.merchantName,
    required this.transactionCount,
    required this.totalSpend,
    required this.transactions,
  });
}

class UniversalSearchResults {
  final String query;
  final List<MerchantSearchResult> merchantResults;
  final List<TransactionItem> transactionResults;
  final List<AccountModel> accountResults;
  final List<SavingsGoal> goalResults;
  final List<String> insightResults;

  UniversalSearchResults({
    required this.query,
    required this.merchantResults,
    required this.transactionResults,
    required this.accountResults,
    required this.goalResults,
    required this.insightResults,
  });

  bool get isEmpty =>
      merchantResults.isEmpty &&
      transactionResults.isEmpty &&
      accountResults.isEmpty &&
      goalResults.isEmpty &&
      insightResults.isEmpty;
}

class UniversalSearchEngine {
  /// Executes 1-step universal search across Merchants, Transactions, Accounts, Goals & Insights
  static UniversalSearchResults searchEverything({
    required String query,
    required List<TransactionItem> transactions,
    required List<AccountModel> accounts,
    required List<SavingsGoal> goals,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return UniversalSearchResults(
        query: query,
        merchantResults: [],
        transactionResults: [],
        accountResults: [],
        goalResults: [],
        insightResults: [],
      );
    }

    final tokens = q
        .split(RegExp(r'[\+\,\s]+'))
        .where((t) => t.trim().isNotEmpty)
        .toList();

    bool matchesAllTokens(TransactionItem tx) {
      if (tokens.isEmpty) return true;
      final fullText =
          '${tx.merchant} ${tx.category} ${tx.account ?? ""} ${tx.notes ?? ""} ${_getMonthName(tx.date.month)}'
              .toLowerCase();
      return tokens.every((token) => fullText.contains(token));
    }

    // 1. Merchant Group Search
    final Map<String, List<TransactionItem>> merchantMap = {};
    for (final tx in transactions) {
      if (tokens.every((token) => tx.merchant.toLowerCase().contains(token))) {
        merchantMap.putIfAbsent(tx.merchant, () => []).add(tx);
      }
    }

    final merchantResults = merchantMap.entries.map((e) {
      final total = e.value
          .where((t) => t.type == TransactionType.debit)
          .fold(0.0, (s, t) => s + t.amount);
      return MerchantSearchResult(
        merchantName: e.key,
        transactionCount: e.value.length,
        totalSpend: total,
        transactions: e.value,
      );
    }).toList()
      ..sort((a, b) => b.totalSpend.compareTo(a.totalSpend));

    // 2. Individual Transactions (Matches multi-facet AND condition)
    final transactionResults = transactions.where(matchesAllTokens).toList();

    // 3. Accounts Search
    final accountResults = accounts.where((a) {
      final text =
          '${a.nickname} ${a.bankName} ${a.maskedAccountNumber}'.toLowerCase();
      return tokens.any((t) => text.contains(t));
    }).toList();

    // 4. Goals Search
    final goalResults = goals.where((g) {
      return tokens.any((t) => g.title.toLowerCase().contains(t));
    }).toList();

    // 5. Money Brain Insights
    final insightResults = <String>[];
    if (tokens.length > 1 && transactionResults.isNotEmpty) {
      final sum = transactionResults
          .where((t) => t.type == TransactionType.debit)
          .fold<double>(0.0, (s, t) => s + t.amount);
      insightResults.add(
          'Multi-Facet Result: ₹${sum.toStringAsFixed(0)} spent matching "${tokens.join(' + ')}".');
    } else if (merchantResults.isNotEmpty) {
      insightResults.add(
          'Top merchant match: ${merchantResults.first.merchantName} (${merchantResults.first.transactionCount} txns, ₹${merchantResults.first.totalSpend.toStringAsFixed(0)} spent).');
    }

    return UniversalSearchResults(
      query: query,
      merchantResults: merchantResults,
      transactionResults: transactionResults,
      accountResults: accountResults,
      goalResults: goalResults,
      insightResults: insightResults,
    );
  }

  static String _getMonthName(int month) {
    const months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december'
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}
