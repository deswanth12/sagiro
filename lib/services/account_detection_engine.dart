import '../models/transaction.dart';

enum AccountType {
  salary,
  savings,
  creditCard,
  upiWallet,
  current,
}

class DetectedAccount {
  final String id;
  final String bankName;
  final AccountType accountType;
  final String last4Digits;
  final String nickname;
  final double balance;
  final String status;
  final int transactionCount;
  final String iconEmoji;

  DetectedAccount({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.last4Digits,
    required this.nickname,
    required this.balance,
    required this.status,
    required this.transactionCount,
    required this.iconEmoji,
  });

  String get displayName => '$nickname ($bankName ••$last4Digits)';
}

class AccountIntelligenceInsight {
  final String emoji;
  final String title;
  final String detail;

  AccountIntelligenceInsight({
    required this.emoji,
    required this.title,
    required this.detail,
  });
}

class AccountDetectionEngine {
  /// Analyzes a stream of transactions from SMS, PDF, CSV, or Manual entries
  /// and automatically infers distinct bank accounts, product types, balances, and nicknames.
  static List<DetectedAccount> detectAccounts(
      List<TransactionItem> transactions) {
    if (transactions.isEmpty) {
      return [];
    }

    final Map<String, List<TransactionItem>> grouped = {};

    for (final tx in transactions) {
      final accStr = tx.account ?? 'Primary Account';
      final cleanDigits = accStr.replaceAll(RegExp(r'[^\d]'), '');
      final last4 = cleanDigits.length >= 4
          ? cleanDigits.substring(cleanDigits.length - 4)
          : (cleanDigits.isNotEmpty ? cleanDigits : 'Primary');

      final bank = _inferBankName(tx);
      final key = '${bank.toLowerCase()}_$last4';

      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final List<DetectedAccount> accounts = [];

    grouped.forEach((key, txs) {
      final parts = key.split('_');
      final last4 = parts.length > 1 ? parts[1] : 'Primary';

      final sampleTx = txs.first;
      final bankName = _inferBankName(sampleTx);
      final isCreditCard =
          sampleTx.merchant.toLowerCase().contains('credit card') ||
              sampleTx.notes?.toLowerCase().contains('credit card') == true;

      final isSalary = txs.any((t) =>
          t.category.toLowerCase() == 'salary' ||
          t.merchant.toLowerCase().contains('salary'));

      AccountType type = AccountType.savings;
      String emoji = '🏦';
      String nickname = 'Primary Account';
      String status = 'Active 🟢';

      if (isCreditCard) {
        type = AccountType.creditCard;
        emoji = '💳';
        nickname = 'Credit Card';
        status = 'Payment Due 🟠';
      } else if (isSalary) {
        type = AccountType.salary;
        emoji = '🏦';
        nickname = 'Salary Account';
      } else if (txs.any((t) => t.merchant.toLowerCase().contains('upi'))) {
        nickname = 'UPI Spending Account';
      }

      double balance = 0.0;
      for (final t in txs) {
        if (t.notes?.contains('Bal:') == true) {
          final balMatch = RegExp(r'Bal:\s*₹([\d,]+)').firstMatch(t.notes!);
          if (balMatch != null) {
            balance = double.tryParse(balMatch.group(1)!.replaceAll(',', '')) ??
                balance;
          }
        }
      }

      if (balance == 0.0) {
        final totalNet = txs.fold<double>(
            0.0,
            (sum, t) =>
                sum +
                (t.type == TransactionType.credit ? t.amount : -t.amount));
        balance = isCreditCard ? -totalNet.abs() : totalNet;
      }

      accounts.add(DetectedAccount(
        id: key,
        bankName: bankName,
        accountType: type,
        last4Digits: last4,
        nickname: nickname,
        balance: balance,
        status: status,
        transactionCount: txs.length,
        iconEmoji: emoji,
      ));
    });

    return accounts;
  }

  /// Generates Smart Account Intelligence Insights derived strictly from real transactions
  static List<AccountIntelligenceInsight> generateIntelligenceInsights(
      List<TransactionItem> transactions) {
    if (transactions.isEmpty) return [];

    final insights = <AccountIntelligenceInsight>[];

    final salaryTxs = transactions
        .where((t) =>
            t.category.toLowerCase() == 'salary' ||
            t.merchant.toLowerCase().contains('salary'))
        .toList();
    if (salaryTxs.isNotEmpty) {
      final salaryTx = salaryTxs.first;
      final bank = _inferBankName(salaryTx);
      insights.add(AccountIntelligenceInsight(
        emoji: '💰',
        title: 'Salary Cycle Pattern',
        detail:
            'Your salary of ₹${salaryTx.amount.toStringAsFixed(0)} is credited to $bank on day ${salaryTx.date.day} of the month.',
      ));
    }

    final shoppingTxs = transactions
        .where((t) => t.category.toLowerCase() == 'shopping')
        .toList();
    if (shoppingTxs.isNotEmpty) {
      final bank = _inferBankName(shoppingTxs.first);
      insights.add(AccountIntelligenceInsight(
        emoji: '🛒',
        title: 'Shopping Account Usage',
        detail:
            'Most online shopping & e-commerce payments (${shoppingTxs.length} txns) come from $bank.',
      ));
    }

    final upiTxs = transactions
        .where((t) =>
            t.merchant.toLowerCase().contains('upi') ||
            (t.notes?.toLowerCase().contains('upi') ?? false))
        .toList();
    if (upiTxs.isNotEmpty) {
      final bank = _inferBankName(upiTxs.first);
      insights.add(AccountIntelligenceInsight(
        emoji: '💸',
        title: 'Daily UPI Spends',
        detail:
            'Daily micro-UPI payments (${upiTxs.length} txns) mostly use your $bank account.',
      ));
    }

    final totalSavings = transactions
        .where((t) => t.type == TransactionType.credit)
        .fold<double>(0.0, (s, t) => s + t.amount);
    if (totalSavings > 0) {
      insights.add(AccountIntelligenceInsight(
        emoji: '📈',
        title: 'Savings Accumulation',
        detail:
            'Total tracked savings & credits accumulated across accounts: ₹${totalSavings.toStringAsFixed(0)}.',
      ));
    }

    return insights;
  }

  static String _inferBankName(TransactionItem tx) {
    // Use only structured fields — rawSms is null for privacy.
    final notes = tx.notes ?? '';
    final merchant = tx.merchant;

    if (notes.contains('HDFC') || merchant.contains('HDFC')) {
      return 'HDFC Bank';
    }
    if (notes.contains('SBI') || merchant.contains('SBI')) {
      return 'State Bank of India (SBI)';
    }
    if (notes.contains('ICICI') || merchant.contains('ICICI')) {
      return 'ICICI Bank';
    }
    if (notes.contains('Axis') || merchant.toUpperCase().contains('AXIS')) {
      return 'Axis Bank';
    }
    if (notes.contains('APGB') || merchant.contains('APGB')) {
      return 'Andhra Pradesh Grameena Bank';
    }
    if (notes.contains('Kotak') || merchant.toUpperCase().contains('KOTAK')) {
      return 'Kotak Mahindra Bank';
    }

    return 'Primary Bank Account';
  }
}
