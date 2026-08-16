import '../models/account_model.dart';
import '../models/account_type.dart';

class AccountMatchResult {
  final AccountModel? matchedAccount;
  final double confidenceScore;
  final String candidateBank;
  final String candidateLast4;
  final AccountCategory candidateCategory;
  final String reason;

  AccountMatchResult({
    this.matchedAccount,
    required this.confidenceScore,
    required this.candidateBank,
    required this.candidateLast4,
    required this.candidateCategory,
    required this.reason,
  });

  bool get isHighConfidenceMatch =>
      confidenceScore >= 0.80 && matchedAccount != null;
  bool get needsUserConfirmation =>
      confidenceScore > 0.40 && confidenceScore < 0.80;
}

class AccountMatchingService {
  /// Matches incoming account details against existing accounts in registry.
  static AccountMatchResult matchAccount({
    required List<AccountModel> existingAccounts,
    required String rawSenderOrText,
    required String? rawAccountStr,
    required String? rawNotesOrMerchant,
  }) {
    final cleanDigits =
        (rawAccountStr ?? rawSenderOrText).replaceAll(RegExp(r'[^\d]'), '');
    final candidateLast4 = cleanDigits.length >= 4
        ? cleanDigits.substring(cleanDigits.length - 4)
        : (cleanDigits.isNotEmpty ? cleanDigits : '');

    final candidateBank =
        inferBankName(rawSenderOrText, rawNotesOrMerchant ?? '');
    final candidateCategory =
        inferAccountCategory(rawSenderOrText, rawNotesOrMerchant ?? '');

    AccountModel? bestMatch;
    double maxConfidence = 0.0;
    String matchReason = 'New account detected';

    for (final acc in existingAccounts) {
      double score = 0.0;

      // 1. Exact match on Last 4 digits
      if (acc.maskedAccountNumber.endsWith(candidateLast4)) {
        score += 0.50;
      }

      // 2. Exact or fuzzy match on Bank Name
      if (acc.bankName.toLowerCase() == candidateBank.toLowerCase() ||
          acc.bankName.toLowerCase().contains(candidateBank.toLowerCase()) ||
          candidateBank.toLowerCase().contains(acc.bankName.toLowerCase())) {
        score += 0.35;
      }

      // 3. Product type match (Credit Card vs Savings vs Salary)
      if (acc.accountType == candidateCategory) {
        score += 0.15;
      }

      if (score > maxConfidence) {
        maxConfidence = score;
        bestMatch = acc;
        matchReason =
            'Matched on bank (${acc.bankName}) and last 4 digits (••$candidateLast4)';
      }
    }

    return AccountMatchResult(
      matchedAccount: maxConfidence >= 0.80 ? bestMatch : null,
      confidenceScore: maxConfidence,
      candidateBank: candidateBank,
      candidateLast4: candidateLast4,
      candidateCategory: candidateCategory,
      reason: matchReason,
    );
  }

  static String inferBankName(String sender, String body) {
    final text = '$sender $body'.toUpperCase();
    if (text.contains('HDFC')) return 'HDFC Bank';
    if (text.contains('SBI') || text.contains('STATE BANK')) {
      return 'State Bank of India (SBI)';
    }
    if (text.contains('ICICI')) return 'ICICI Bank';
    if (text.contains('AXIS')) return 'Axis Bank';
    if (text.contains('KOTAK')) return 'Kotak Mahindra Bank';
    if (text.contains('APGB') || text.contains('ANDHRA PRADESH GRAMEENA')) {
      return 'Andhra Pradesh Grameena Bank';
    }
    if (text.contains('PNB') || text.contains('PUNJAB NATIONAL')) {
      return 'Punjab National Bank';
    }
    if (text.contains('BOB') || text.contains('BANK OF BARODA')) {
      return 'Bank of Baroda';
    }
    if (text.contains('CANARA')) return 'Canara Bank';
    if (text.contains('IDFC')) return 'IDFC FIRST Bank';
    if (text.contains('INDUSIND')) return 'IndusInd Bank';
    if (text.contains('PAYTM')) return 'Paytm Payments Bank';

    return 'Primary Bank';
  }

  static AccountCategory inferAccountCategory(String sender, String body) {
    final text = '$sender $body'.toLowerCase();
    if (text.contains('credit card') ||
        text.contains('card ending') ||
        text.contains('crd') ||
        text.contains('card_statement') ||
        text.contains('card')) {
      return AccountCategory.creditCard;
    }
    if (text.contains('salary') || text.contains('sal credited')) {
      return AccountCategory.salary;
    }
    if (text.contains('loan') || text.contains('emi')) {
      return AccountCategory.loan;
    }
    if (text.contains('wallet') ||
        text.contains('gpay') ||
        text.contains('phonepe') ||
        text.contains('cash')) {
      return AccountCategory.wallet;
    }
    if (text.contains('current a/c') || text.contains('current account')) {
      return AccountCategory.current;
    }

    return AccountCategory.savings;
  }
}
