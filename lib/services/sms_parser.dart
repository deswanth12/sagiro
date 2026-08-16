import '../models/transaction.dart';
import '../models/canonical_transaction_identity.dart';
import 'merchant_intelligence_service.dart';
import 'sms_classifier.dart';

enum ConfidenceTier {
  high, // 🟢 95-100%: Exact bank pattern & verified merchant
  medium, // 🟡 70-94%: Generic financial SMS matched
  low // 🔴 Below 70%: Needs user confirmation before saving
}

class SmsParserResult {
  final TransactionItem transaction;
  final String? bankName;
  final double? remainingBalance;
  final int confidenceScore; // 0 - 100%
  final ConfidenceTier confidenceTier;
  final String confidenceExplanation;
  final String parserVersion;
  final bool isUserAssigned;
  final String? paymentMethod;
  final String? accountOrCard;

  SmsParserResult({
    required this.transaction,
    this.bankName,
    this.remainingBalance,
    required this.confidenceScore,
    required this.confidenceTier,
    required this.confidenceExplanation,
    this.parserVersion = 'v1.4.2',
    this.isUserAssigned = false,
    this.paymentMethod,
    this.accountOrCard,
  });

  bool get needsReview =>
      confidenceTier == ConfidenceTier.low || confidenceScore < 70;
}

class ParserAnalyticsData {
  static int totalProcessed = 0;
  static int highConfidenceCount = 0;
  static int mediumConfidenceCount = 0;
  static int lowConfidenceCount = 0;
  static int unknownSendersCount = 0;
  static int duplicatesIgnoredCount = 0;
  static const String parserVersion = 'v1.4.2';
}

class SmsParser {
  /// Pre-compiled Static Regular Expressions (Compiled once at class load)
  static final RegExp _cleanSenderRegex = RegExp(r'[^A-Z0-9]');

  static final List<RegExp> _amountRegexes = [
    RegExp(
        r'(?:debited|credited|spent|paid|received|sent|withdrawn)\s*(?:by|of|for)?\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false),
    RegExp(
        r'(?:amount|txn|transaction)\s*(?:of)?\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false),
    RegExp(
        r'(?:plan\s*(?:name|amount|amt|price)?|mrp|pack)\s*:\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false),
    RegExp(r'for\s*(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false),
    RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:rs\.?|inr|₹)', caseSensitive: false),
  ];

  static final List<RegExp> _balanceRegexes = [
    RegExp(
        r'(?:bal|balance|avail bal|available bal|avail\.? bal\.?|cl bal|closing bal|current bal)\s*(?:is|:|=)?\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false),
    RegExp(
        r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:is your|bal|balance|avail|cl bal)',
        caseSensitive: false),
  ];

  static final List<RegExp> _refRegexes = [
    RegExp(
        r'(?:ref|rrn|utr|txn id|txn ref|upi ref|ref no|reference|transaction\s*id)\s*[:#\-\s]?\s*([a-z0-9]{6,30})',
        caseSensitive: false),
    RegExp(r'upi/([a-z0-9]{6,25})', caseSensitive: false),
  ];

  /// Expanded Date Patterns for Explicit Date Extraction in SMS:
  /// 1. ISO format: YYYY-MM-DD / YYYY/MM/DD / YYYY.MM.DD
  static final RegExp _dateIsoRegex = RegExp(
    r'\b(\d{4})[-/\.](0?[1-9]|1[0-2])[-/\.](0?[1-9]|[12]\d|3[01])\b',
  );

  /// 2. Day-Month-Year (Numeric or Month Abbreviation/Full Name): 13/08/2026, 13-Aug-2026, 13 August 2026, 13.08.26
  static final RegExp _dateFullRegex = RegExp(
    r'\b(0?[1-9]|[12]\d|3[01])[-/\.\s]+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|0?[1-9]|1[0-2])[-/\.\s]+(\d{2,4})\b',
    caseSensitive: false,
  );

  /// 3. Day-Month Yearless: 13 Aug, 31 Dec, 13/08, 13-Aug, 13.08, 13 August
  static final RegExp _dateYearlessRegex = RegExp(
    r'\b(?:on\s+|dt\s+|date\s+)?(0?[1-9]|[12]\d|3[01])[-/\.\s]+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|0?[1-9]|1[0-2])\b',
    caseSensitive: false,
  );

  static final RegExp _vpaRegex =
      RegExp(r'\b([a-zA-Z0-9\.\-_]{2,}@[a-zA-Z0-9]+)\b', caseSensitive: false);

  static final RegExp _accountRegex = RegExp(
      r'(?:a/c|acct|account|acc|ac|card|jio\s*number|mobile\s*no|mobile\s*number|phone\s*no)\s*(?:no\.?)?\s*:?\s*([xX\*]*\d{3,10})',
      caseSensitive: false);

  /// Pre-compiled Static Regular Expression for Fast Financial Keyword Early Rejection.
  /// Uses lookaround boundaries (?<![A-Za-z]) ... (?![A-Za-z]) to prevent false-positives
  /// on English words containing 'rs' (e.g. 'first', 'hours', 'offers', 'orders', 'users', 'person', 'accountant').
  /// Handles symbols (₹), slash expressions (a/c, acct), currency tags (rs, inr), and action verbs.
  static final RegExp _financialKeywordRegex = RegExp(
    r'(?<![A-Za-z])(?:rs\.?|inr|₹|debited|credited|withdrawn|spent|paid|received|sent|transferred|txn|upi|neft|imps|atm|pos|a/c|acct|bank|account|recharge|plan)(?![A-Za-z])',
    caseSensitive: false,
  );

  /// Fast early rejection for non-financial messages
  static bool hasFinancialKeywords(String text) {
    if (text.isEmpty) return false;
    return _financialKeywordRegex.hasMatch(text);
  }

  /// Self-Learning User Assigned Sender Mappings (Persisted memory)
  static final Map<String, String> userAssignedSenders = {};

  /// Register custom user bank assignment for unknown sender
  static void registerCustomSenderMapping(
      String senderHeader, String bankName) {
    final clean = senderHeader.toUpperCase().replaceAll(_cleanSenderRegex, '');
    if (clean.isNotEmpty) {
      userAssignedSenders[clean] = bankName;
    }
  }

  /// Financial Senders Registry: 50 Commercial Banks + 5 UPI Apps + 16 RRBs = 71 Total
  static final Map<String, List<String>> financialSendersIndia = {
    // 50 Major Commercial Banks
    'State Bank of India (SBI)': [
      'SBI',
      'SBIINB',
      'SBIPSG',
      'SBICRD',
      'SBIPAY'
    ],
    'HDFC Bank': ['HDFCBK', 'HDFCCRD', 'HDFCPY'],
    'ICICI Bank': ['ICICIB', 'ICICICRD', 'ICICIPAY'],
    'Axis Bank': ['AXISBK', 'AXISCRD', 'AXISPAY'],
    'Punjab National Bank (PNB)': ['PNBSMS', 'PNBBNK', 'PNB'],
    'Bank of Baroda': ['BOBTXN', 'BARBNK', 'BOB'],
    'Canara Bank': ['CANBNK', 'CNRBNK', 'CANARA'],
    'Union Bank of India': ['UNIONB', 'UBIBNK', 'UNION'],
    'Indian Bank': ['INDBNK', 'INDIANB'],
    'Bank of India': ['BOITXN', 'BKIDBNK', 'BOI'],
    'Central Bank of India': ['CBISMS', 'CBINBNK', 'CBI'],
    'UCO Bank': ['UCOBNK', 'UCBABNK', 'UCO'],
    'Punjab & Sind Bank': ['PSBBNK', 'PSBSMS', 'PSB'],
    'Indian Overseas Bank': ['IOBBNK', 'IOBSMS', 'IOB'],
    'Bank of Maharashtra': ['MAHABK', 'BOMBNK', 'MAHA'],
    'IDBI Bank': ['IDBIBK', 'IDBISMS', 'IDBI'],
    'Yes Bank': ['YESBNK', 'YESCRD', 'YESPAY'],
    'IDFC FIRST Bank': ['IDFCFB', 'IDFCBK', 'IDFC'],
    'Kotak Mahindra Bank': ['KOTAKB', 'KOTAK', 'KOTAKP'],
    'IndusInd Bank': ['INDUSB', 'INDUS', 'INDUSI'],
    'AU Small Finance Bank': ['AUBANK', 'AUBNK', 'AUSFB'],
    'Equitas Small Finance Bank': ['EQUITAS', 'EQSFB'],
    'Ujjivan Small Finance Bank': ['UJJIVAN', 'UJSFB'],
    'ESAF Small Finance Bank': ['ESAFSFB', 'ESAF'],
    'Jana Small Finance Bank': ['JANABANK', 'JANASFB'],
    'Suryoday Small Finance Bank': ['SURYODAY', 'SURYOD'],
    'Utkarsh Small Finance Bank': ['UTKARSH', 'UTKSFB'],
    'North East Small Finance Bank': ['NESFB', 'NESFBNK'],
    'Capital Small Finance Bank': ['CAPITAL', 'CAPSFB'],
    'Unity Small Finance Bank': ['UNITY', 'UNITYSFB'],
    'Fincare Small Finance Bank': ['FINCARE', 'FINSFB'],
    'Karnataka Bank': ['KRNTAK', 'KBLBNK', 'KBL'],
    'Karur Vysya Bank': ['KVBBNK', 'KVBSMS', 'KVB'],
    'South Indian Bank': ['SIBLBNK', 'SOUTHIN', 'SIB'],
    'Tamilnad Mercantile Bank': ['TMBLBNK', 'TMBSMS', 'TMB'],
    'City Union Bank': ['CUBBNK', 'CITYUB', 'CUB'],
    'DCB Bank': ['DCBBNK', 'DCBSMS', 'DCB'],
    'RBL Bank': ['RBLBNK', 'RBLCRD', 'RBL'],
    'CSB Bank': ['CSBBNK', 'CSBSMS', 'CSB'],
    'Federal Bank': ['FEDBNK', 'FEDERAL', 'FED'],
    'Bandhan Bank': ['BANDHAN', 'BNDHBNK'],
    'DBS Bank India': ['DBSBNK', 'DBSIN'],
    'Standard Chartered Bank India': ['SCBANK', 'SCBIN'],
    'HSBC India': ['HSBCIN', 'HSBC'],
    'Citibank India': ['CITIBK', 'CITI'],
    'Deutsche Bank India': ['DEUSTB', 'DBIN'],
    'JPMorgan Chase Bank India': ['JPMCH', 'JPMORGAN'],
    'Bank of America India': ['BOFA', 'BOFAIN'],
    'BNP Paribas India': ['BNPPAR', 'BNP'],
    'MUFG Bank India': ['MUFGBK', 'MUFG'],

    // Major Payment / UPI Apps & Telecom Billers
    'Google Pay': ['GPAY', 'GOOGPAY', 'GOOGLEPAY'],
    'PhonePe': ['PHONEPE', 'PPE', 'PPHON'],
    'Paytm': ['PAYTM', 'PAYTMP', 'PYTM'],
    'Amazon Pay': ['AMAZON', 'AMZPAY', 'AMZNPAY'],
    'BHIM UPI': ['BHIM', 'NPCI', 'UPI'],
    'Jio / JioPay': [
      'JIOPAY',
      'JIO',
      'JIOFIB',
      'JIONET',
      'JIOTXN',
      'JMSMS',
      'JMJIO',
      'JIOMOB',
      'JMS'
    ],
    'Airtel': ['AIRTEL', 'AIRBNK', 'AIRTELPY', 'AIRPAY'],
    'Vi / Vodafone Idea': ['VODAFONE', 'IDEA', 'VIPAY', 'VISMS', 'VIL'],
    'BSNL': ['BSNL', 'BSNLMS', 'BSNLPAY'],

    // 16 Regional Rural Banks (RRBs)
    'Andhra Pradesh Grameena Bank': [
      'APGBNK',
      'APGBANK',
      'APGB',
      'APGRAM',
      'APGBANKT'
    ],
    'Telangana Grameena Bank': ['TGBNK', 'TGB', 'TGRAM'],
    'Karnataka Grameena Bank': ['KGBNK', 'KGRAM', 'KGB'],
    'Kerala Grameena Bank': ['KLGBNK', 'KLGRAM', 'KERALAGB'],
    'Tamil Nadu Grama Bank': ['TNGBNK', 'TNGRAM', 'TNGB'],
    'Uttar Pradesh Gramin Bank': ['UPGBNK', 'UPGRAM', 'UPGB'],
    'Rajasthan Gramin Bank': ['RMGBNK', 'RMGRAM', 'RMGB'],
    'Bihar Gramin Bank': ['MBGBNK', 'MBGRAM', 'MBGB'],
    'Odisha Grameen Bank': ['OGBNK', 'OGRAM', 'OGB'],
    'Maharashtra Gramin Bank': ['MGBNK', 'MGRAM', 'MGB'],
    'Punjab Gramin Bank': ['PGBNK', 'PGRAM', 'PGB'],
    'West Bengal Gramin Bank': ['PBGBNK', 'PBGRAM', 'PBGB'],
    'Assam Gramin Bank': ['AGVB', 'AGVBNK', 'AGB'],
    'Gujarat Gramin Bank': ['DGGB', 'DGGBNK', 'GGB'],
    'Chhattisgarh Gramin Bank': ['CRGB', 'CRGBNK', 'CGB'],
    'Uttarakhand Gramin Bank': ['UKGB', 'UKGBNK', 'UKB'],

    // Major Regional & Cooperative Banks
    'TJSB Sahakari Bank': ['TJSBNK', 'TJSB', 'TJSBSMS'],
    'Saraswat Bank': ['SARASW', 'SRCBNK', 'SARASWAT'],
    'Cosmos Co-operative Bank': ['COSMOS', 'COSMOSB'],
    'Abhyudaya Co-operative Bank': ['ABHYUD', 'ABHYBNK'],
    'Shamrao Vithal Co-op Bank (SVC)': ['SVCBNK', 'SVCBANK'],
    'Bharat Co-operative Bank': ['BHARAT', 'BHARATB'],
  };

  /// Main Flexible Multi-Layered Parser
  static TransactionItem? parseSms(String body, String sender,
      {DateTime? smsDate}) {
    final result = parseSmsDetailed(body, sender, smsDate: smsDate);
    return result?.transaction;
  }

  /// Adaptive Parser with Layered Pattern Detection & Confidence Scoring
  static SmsParserResult? parseSmsDetailed(String body, String sender,
      {DateTime? smsDate}) {
    if (body.isEmpty || body.length > 800) return null;

    // Stage 1: Cheap classification. Only financialTransaction candidates proceed.
    final classification = SmsClassifier.classify(body, sender);
    if (!classification.isCandidateForParsing) {
      return null;
    }

    final lower = body.toLowerCase();

    // Fast Early Rejection: Ignore non-financial messages
    if (!hasFinancialKeywords(lower)) return null;

    // Safety Guard 1: Ignore OTPs, Passwords, and Security Codes
    if (lower.contains('otp') ||
        lower.contains('verification code') ||
        lower.contains('do not share') ||
        lower.contains('secret code') ||
        lower.contains('login code') ||
        lower.contains('one time password') ||
        lower.contains('security code') ||
        lower.contains('authorization code') ||
        lower.contains('auth code')) {
      return null;
    }

    // Safety Guard 2: Ignore Failed, Declined, or Unsuccessful Transactions
    if (lower.contains('txn failed') ||
        lower.contains('transaction failed') ||
        lower.contains('declined') ||
        lower.contains('unsuccessful') ||
        lower.contains('could not be processed') ||
        lower.contains('payment failed') ||
        lower.contains('insufficient balance') ||
        lower.contains('failed due to')) {
      return null;
    }

    // Safety Guard 3: Ignore Marketing, Promotional, & Pre-Approved Loan Offers
    if (lower.contains('apply now') ||
        lower.contains('pre-approved') ||
        lower.contains('get loan') ||
        lower.contains('click to apply') ||
        lower.contains('instant loan') ||
        lower.contains('eligible for loan') ||
        lower.contains('special offer') ||
        lower.contains('flat discount') ||
        lower.contains('use coupon') ||
        lower.contains('cashback offer') ||
        lower.contains('exclusive offer') ||
        lower.contains('lucky winner') ||
        lower.contains('recharge now') ||
        lower.contains('avail offer')) {
      return null;
    }

    // Safety Guard 4: Ignore Delivery & Order Status (when no payment transaction)
    if ((lower.contains('out for delivery') ||
            lower.contains('order dispatched') ||
            lower.contains('arriving today') ||
            lower.contains('package delivered')) &&
        !lower.contains('debited') &&
        !lower.contains('credited') &&
        !lower.contains('paid rs') &&
        !lower.contains('spent rs')) {
      return null;
    }

    // Safety Guard 5: Ignore Security & Account Alerts
    if (lower.contains('login detected') ||
        lower.contains('logged in from') ||
        lower.contains('password changed') ||
        lower.contains('kyc pending') ||
        lower.contains('update your kyc')) {
      return null;
    }

    // Step 1: Detect Bank & User-Assigned Custom Mapping
    final cleanSender =
        sender.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final bool isUserAssigned = userAssignedSenders.containsKey(cleanSender);
    final String? bankName = isUserAssigned
        ? userAssignedSenders[cleanSender]
        : (identifyBank(sender) ?? _detectBankInBody(body));

    // Step 2: Determine Transaction Type (Debit, Credit, ATM, Interest, Reversal, Bill, Refund)
    final type = _extractTransactionType(lower);
    if (type == null) return null;

    // Step 3: Extract Amount
    final double? amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    // Step 4: Extract Merchant / Payee with 8-Priority Engine
    final (extractedMerchant, merchantTier) =
        _extractMerchantWithConfidence(body, sender);
    final String merchant = extractedMerchant;

    // Step 5: Extract Account & Balance
    final String? account = _extractAccount(body);
    final double? balance = _extractBalance(body);

    // Step 6: Extract Date if present in SMS
    final DateTime parsedDate = parseTransactionDate(body, smsDate: smsDate);

    // Step 7: Extract Payment Method
    final paymentMethod = _extractPaymentMethod(lower);

    // Step 8: Calculate Multi-Layered Confidence Score (0 - 100%)
    int score = 0;
    final explanationParts = <String>[];
    if (bankName != null) {
      score += 30;
      explanationParts.add('Verified Bank ($bankName)');
    } else {
      explanationParts.add('Generic SMS Header');
      ParserAnalyticsData.unknownSendersCount++;
    }

    if (isUserAssigned) {
      score += 10;
      explanationParts.add('User Custom Rule');
    }
    if (amount > 0) {
      score += 25;
      explanationParts.add('Amount ₹${amount.toStringAsFixed(0)} Extracted');
    }
    score += 15; // valid transaction type matched
    explanationParts
        .add('${type == TransactionType.debit ? "Debit" : "Credit"} Inferred');

    if (merchantTier == ConfidenceTier.high) {
      score += 20;
      explanationParts.add('Explicit Merchant ($merchant)');
    } else if (merchantTier == ConfidenceTier.medium) {
      score += 10;
      explanationParts.add('Inferred Merchant ($merchant)');
    } else {
      explanationParts.add('Sender Fallback ($merchant)');
    }

    if (account != null) {
      score += 5;
      explanationParts.add('Account A/C $account Detected');
    }

    score = score.clamp(0, 100);

    ConfidenceTier tier = merchantTier;
    if (score < 60) {
      tier = ConfidenceTier.low;
      ParserAnalyticsData.lowConfidenceCount++;
    } else if (score < 85) {
      tier = ConfidenceTier.medium;
      ParserAnalyticsData.mediumConfidenceCount++;
    } else {
      tier = ConfidenceTier.high;
      ParserAnalyticsData.highConfidenceCount++;
    }

    ParserAnalyticsData.totalProcessed++;

    final explanation =
        '${tier.name.toUpperCase()} Confidence: ${explanationParts.join(' • ')}';

    // Build Notes & Reference Extraction
    final parts = <String>[];
    if (bankName != null) parts.add(bankName);
    if (paymentMethod != null) parts.add(paymentMethod);
    if (balance != null) parts.add('Bal: ₹${balance.toStringAsFixed(0)}');
    final notes = parts.isNotEmpty ? parts.join(' • ') : null;
    final extractedRef = _extractTransactionReference(body);

    final tx = TransactionItem(
      amount: amount,
      merchant: merchant,
      category: _detectCategoryFromText(lower, merchant),
      type: type,
      source: TransactionSource.sms,
      date: parsedDate,
      account: account,
      notes: notes,
      transactionReference: extractedRef,
      rawSms: null,
    );

    return SmsParserResult(
      transaction: tx,
      bankName: bankName,
      remainingBalance: balance,
      confidenceScore: score,
      confidenceTier: tier,
      confidenceExplanation: explanation,
      parserVersion: ParserAnalyticsData.parserVersion,
      isUserAssigned: isUserAssigned,
      paymentMethod: paymentMethod,
      accountOrCard: account,
    );
  }

  /// Generates a deterministic canonical fingerprint for duplicate detection
  static String generateFingerprint({
    required String profileId,
    required DateTime date,
    required double amount,
    required TransactionType type,
    required String merchant,
    String? reference,
  }) {
    final tempTx = TransactionItem(
      amount: amount,
      merchant: merchant,
      category: 'General',
      type: type,
      source: TransactionSource.sms,
      date: date,
      profileId: profileId,
      transactionReference: reference,
    );
    return CanonicalTransactionIdentity.computeFingerprint(tempTx);
  }

  static String? _extractPaymentMethod(String lowerBody) {
    if (lowerBody.contains('upi') ||
        lowerBody.contains('vpa') ||
        lowerBody.contains('@')) {
      return 'UPI';
    }
    if (lowerBody.contains('neft')) return 'NEFT';
    if (lowerBody.contains('imps')) return 'IMPS';
    if (lowerBody.contains('atm') ||
        lowerBody.contains('cash withdrawal') ||
        lowerBody.contains('withdrawn from atm')) {
      return 'ATM';
    }
    if (lowerBody.contains('pos') ||
        lowerBody.contains('card') ||
        lowerBody.contains('credit card') ||
        lowerBody.contains('debit card')) {
      return 'Card';
    }
    if (lowerBody.contains('netbanking') ||
        lowerBody.contains('inb') ||
        lowerBody.contains('internet banking')) {
      return 'NetBanking';
    }
    return null;
  }

  /// Detect Sender ID against 71 Major Financial Senders in India
  static String? identifyBank(String senderHeader) {
    final upperHeader = senderHeader.toUpperCase();
    final parts = upperHeader
        .split(RegExp(r'[-_]'))
        .map((p) => p.replaceAll(RegExp(r'[^A-Z0-9]'), ''))
        .toList();

    // 1. Try exact match on sub-code
    for (final part in parts.reversed) {
      if (part.isEmpty) continue;
      for (final entry in financialSendersIndia.entries) {
        for (final code in entry.value) {
          if (part == code) return entry.key;
        }
      }
    }

    // 2. Substring fallback
    final fullClean = upperHeader.replaceAll(RegExp(r'[^A-Z]'), '');
    for (final entry in financialSendersIndia.entries) {
      for (final code in entry.value) {
        if (fullClean.contains(code)) return entry.key;
      }
    }
    return null;
  }

  static String? _detectBankInBody(String body) {
    for (final entry in financialSendersIndia.entries) {
      if (body.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.key;
      }
    }
    return null;
  }

  static TransactionType? _extractTransactionType(String lowerBody) {
    final debitIdx = lowerBody.indexOf('debited');
    final creditIdx = lowerBody.indexOf('credited');

    if (debitIdx != -1 && creditIdx != -1) {
      if (lowerBody.contains('credited in your') ||
          lowerBody.contains('credited to your')) {
        return TransactionType.credit;
      }
      return debitIdx < creditIdx
          ? TransactionType.debit
          : TransactionType.credit;
    }

    if (lowerBody.contains('credited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('refunded') ||
        lowerBody.contains('salary credited') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('added') ||
        lowerBody.contains('interest credit') ||
        lowerBody.contains('reversal of rs')) {
      return TransactionType.credit;
    } else if (lowerBody.contains('debited') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('sent to') ||
        lowerBody.contains('sent rs') ||
        lowerBody.contains('txn of') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('withdrawal') ||
        lowerBody.contains('purchase of') ||
        lowerBody.contains('atm wdl') ||
        lowerBody.contains('emi deduction') ||
        lowerBody.contains('transferred') ||
        lowerBody.contains('transfer') ||
        lowerBody.contains('recharge of') ||
        lowerBody.contains('recharge')) {
      return TransactionType.debit;
    }
    return null;
  }

  static double? _extractAmount(String body) {
    // 1. Action-tied amount regexes (highest priority)
    final actionRegexes = [
      RegExp(
          r'(?:plan\s*(?:name|amount|amt|price)?|mrp|pack)\s*:\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
      RegExp(
          r'(?:debited|credited|spent|paid|received|sent|withdrawn|recharge\s+of|recharge)\s*(?:by|of|for)?\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
      RegExp(
          r'(?:debited|credited|spent|paid|received|sent|withdrawn)\s*(?:by|of|for)?\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
      RegExp(
          r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:debited|credited|spent|paid|received|sent|withdrawn)',
          caseSensitive: false),
      RegExp(
          r'(?:amount|txn|transaction)\s*(?:of)?\s*(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
          caseSensitive: false),
    ];

    for (final reg in actionRegexes) {
      final match = reg.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final val = double.tryParse(amountStr);
        if (val != null && val > 0) return val;
      }
    }

    // 2. Fallback to general currency patterns with immediate balance exclusion
    for (final reg in _amountRegexes) {
      final matches = reg.allMatches(body);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final start = (match.start - 12).clamp(0, body.length);
          final preceding = body.substring(start, match.start).toLowerCase();

          // Skip if immediately preceded by balance keywords
          if (preceding.contains('bal') ||
              preceding.contains('balance') ||
              preceding.contains('avail')) {
            continue;
          }

          final amountStr = match.group(1)!.replaceAll(',', '');
          final val = double.tryParse(amountStr);
          if (val != null && val > 0) return val;
        }
      }
    }
    return null;
  }

  static double? _extractBalance(String body) {
    for (final reg in _balanceRegexes) {
      final match = reg.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final balStr = match.group(1)!.replaceAll(',', '');
        return double.tryParse(balStr);
      }
    }
    return null;
  }

  static String? _extractTransactionReference(String body) {
    for (final reg in _refRegexes) {
      final match = reg.firstMatch(body);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  /// Centralized Transaction Date Parser with 3-Tier Precedence:
  /// 1. Explicit transaction date parsed from SMS text
  /// 2. SMS message received timestamp (smsDate)
  /// 3. Fallback to DateTime.now() ONLY if smsDate is null
  static DateTime parseTransactionDate(String body, {DateTime? smsDate}) {
    final refDate = smsDate ?? DateTime.now();

    // 1. Try ISO Date (YYYY-MM-DD)
    final isoMatch = _dateIsoRegex.firstMatch(body);
    if (isoMatch != null) {
      final year = int.tryParse(isoMatch.group(1)!) ?? refDate.year;
      final month = (int.tryParse(isoMatch.group(2)!) ?? 1).clamp(1, 12);
      final day = (int.tryParse(isoMatch.group(3)!) ?? 1).clamp(1, 31);
      return DateTime(year, month, day);
    }

    // 2. Try Full Date (DD-MM-YYYY, DD/MMM/YYYY, DD.MM.YY, etc.)
    final fullMatch = _dateFullRegex.firstMatch(body);
    if (fullMatch != null) {
      final day = (int.tryParse(fullMatch.group(1)!) ?? 1).clamp(1, 31);
      final monthStr = fullMatch.group(2)!;
      final yearStr = fullMatch.group(3)!;
      final year = int.tryParse(yearStr.length == 2 ? '20$yearStr' : yearStr) ??
          refDate.year;
      final month = _parseMonthString(monthStr);
      return DateTime(year, month, day);
    }

    // 3. Try Year-less Date (DD Aug, 31 Dec, 13/08)
    final yearlessMatch = _dateYearlessRegex.firstMatch(body);
    if (yearlessMatch != null) {
      final day = (int.tryParse(yearlessMatch.group(1)!) ?? 1).clamp(1, 31);
      final monthStr = yearlessMatch.group(2)!;
      final month = _parseMonthString(monthStr);

      // Deterministic Year Inference Rule:
      // Use smsDate as the reference year.
      // E.g., if smsDate is 2026-01-02 and SMS text is 31 Dec, month (12) > refDate.month (1) + 1,
      // so stored year is 2025 (2025-12-31).
      int inferredYear = refDate.year;
      if (month > refDate.month + 1) {
        inferredYear = refDate.year - 1;
      }
      return DateTime(inferredYear, month, day);
    }

    // 4. Fallback to SMS received date or current time
    return refDate;
  }

  static int _parseMonthString(String monthStr) {
    final parsed = int.tryParse(monthStr);
    if (parsed != null) return parsed.clamp(1, 12);

    const monthNames = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec'
    ];
    final clean = monthStr.toLowerCase();
    for (int i = 0; i < monthNames.length; i++) {
      if (clean.startsWith(monthNames[i])) return i + 1;
    }
    return 1;
  }

  static (String merchant, ConfidenceTier confidenceTier)
      _extractMerchantWithConfidence(String body, String sender) {
    final lower = body.toLowerCase();

    // Priority 1: UPI VPA / Payee (e.g. transferred to rahul@okaxis -> Rahul)
    final vpaMatch = _vpaRegex.firstMatch(body);
    if (vpaMatch != null && vpaMatch.group(1) != null) {
      final vpa = vpaMatch.group(1)!.trim();
      final normalized = MerchantIntelligenceService.normalizeMerchant(vpa);
      return (normalized, ConfidenceTier.high);
    }

    // Priority 2: Explicit merchant / payee / biller phrases in body
    final explicitPatterns = [
      RegExp(
          r'(?:paid\s+to|payment\s+to|transferred\s+to|transfer\s+to|sent\s+to|paid\s+at|spent\s+at|spent\s+on\s+card\s+at|purchase\s+at|purchase\s+of|debited\s+for|debited\s+towards|towards)\s+([A-Za-z0-9\s&\.\-_]{2,40}?)(?:\s+on|\s+via|\s+ref|\s+using|\s+avl|\s+bal|\s+a/c|\s+acct|\.|\s*\(|\s*\-|$)',
          caseSensitive: false),
      RegExp(
          r'UPI\s+txn\s+of\s+(?:Rs\.?|₹|INR)?\s*[\d,.]+\s+to\s+([A-Za-z0-9\s&\.\-_]{2,30})',
          caseSensitive: false),
      RegExp(r'info\s+([A-Za-z0-9\s&\.\-_]{2,30})(?:\s+on|\s+via|\.|\s*\(|$)',
          caseSensitive: false),
    ];

    for (final reg in explicitPatterns) {
      final match = reg.firstMatch(body);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        final candidateLower = candidate.toLowerCase();
        if (candidate.isNotEmpty &&
            !candidateLower.contains('account') &&
            !candidateLower.contains('your a/c') &&
            !candidateLower.startsWith('rs') &&
            !candidateLower.startsWith('inr') &&
            !candidateLower.startsWith('xx') &&
            candidate.length >= 2) {
          final normalized =
              MerchantIntelligenceService.normalizeMerchant(candidate);
          return (normalized, ConfidenceTier.high);
        }
      }
    }

    // Priority 3: POS Merchant
    final posMatch = RegExp(
            r'(?:POS|pos\s+purchase\s+at|pos\s+txn\s+at)\s+([A-Za-z0-9\s&\.\-_]{3,35})',
            caseSensitive: false)
        .firstMatch(body);
    if (posMatch != null && posMatch.group(1) != null) {
      final normalized =
          MerchantIntelligenceService.normalizeMerchant(posMatch.group(1)!);
      return (normalized, ConfidenceTier.high);
    }

    // Priority 4: NEFT / IMPS Beneficiary
    final impsMatch = RegExp(
            r'(?:NEFT|IMPS)\s+(?:txn\s+to|to|transfer\s+to)\s+([A-Za-z0-9\s&\.\-_]{3,35})',
            caseSensitive: false)
        .firstMatch(body);
    if (impsMatch != null && impsMatch.group(1) != null) {
      final normalized =
          MerchantIntelligenceService.normalizeMerchant(impsMatch.group(1)!);
      return (normalized, ConfidenceTier.high);
    }

    // Priority 5 & 6: Specific Billers & Subscriptions (Longest Match First)
    final knownServices = [
      'Airtel Xstream Fiber',
      'Airtel Xstream',
      'Airtel Broadband',
      'Airtel DTH',
      'Google One',
      'YouTube Premium',
      'Amazon Prime',
      'Amazon Pay',
      'Swiggy Instamart',
      'Swiggy Dineout',
      'Reliance Digital',
      'Reliance Fresh',
      'Reliance Retail',
      'Jio Fiber',
      'Disney+ Hotstar',
      'Hotstar',
      'Netflix',
      'Spotify',
      'ChatGPT',
      'Apple Services',
      'Swiggy',
      'Zomato',
      'Blinkit',
      'Zepto',
      'BigBasket',
      'Amazon',
      'Flipkart',
      'Myntra',
      'Uber',
      'Ola',
      'Rapido',
      'Indian Oil',
      'HPCL',
      'BPCL',
      'Apollo Pharmacy',
      'PharmEasy',
      'Zerodha',
      'Groww',
      'Upstox',
      'Paytm',
      'PhonePe',
      'Google Pay',
      'CRED',
      'IRCTC',
      'BookMyShow',
      'BESCOM',
      'Tata Power',
      'Adani Electricity',
      'Jio',
      'Airtel',
    ];

    if (lower.contains('salary credited') ||
        lower.contains('salary credit') ||
        lower.contains('salary')) {
      return ('Salary Account', ConfidenceTier.medium);
    }
    if (lower.contains('interest credit') ||
        lower.contains('interest credited') ||
        lower.contains('interest')) {
      return ('Bank Interest', ConfidenceTier.medium);
    }

    if (lower.contains('recharge')) {
      final upperSender = sender.toUpperCase();
      if (lower.contains('airtel') || upperSender.contains('AIRTEL')) {
        return ('Airtel Recharge', ConfidenceTier.high);
      }
      if (lower.contains('jio') || upperSender.contains('JIO')) {
        return ('Jio Recharge', ConfidenceTier.high);
      }
      if (lower.contains('vi') ||
          lower.contains('vodafone') ||
          upperSender.contains('VI')) {
        return ('Vi Recharge', ConfidenceTier.high);
      }
      if (lower.contains('bsnl') || upperSender.contains('BSNL')) {
        return ('BSNL Recharge', ConfidenceTier.high);
      }
      return ('Mobile Recharge', ConfidenceTier.high);
    }

    for (final ks in knownServices) {
      if (RegExp(r'\b' + RegExp.escape(ks) + r'\b', caseSensitive: false)
          .hasMatch(body)) {
        final normalized = MerchantIntelligenceService.normalizeMerchant(ks);
        return (normalized, ConfidenceTier.high);
      }
    }

    // Priority 7: ATM Cash Withdrawal + Location
    if (lower.contains('atm wdl') ||
        lower.contains('cash withdrawal') ||
        lower.contains('withdrawn from atm') ||
        lower.contains('atm withdrawal') ||
        lower.contains('atm wdr') ||
        lower.contains('at atm')) {
      final atmLocMatch = RegExp(
              r'at\s+atm\s+([A-Za-z0-9\s]+?)(?:\s+on|\s+ref|\s+dt|\s+avl|\.|\s*\(|\s*\-|$)',
              caseSensitive: false)
          .firstMatch(body);
      if (atmLocMatch != null && atmLocMatch.group(1) != null) {
        final loc = atmLocMatch.group(1)!.trim();
        final normalized =
            MerchantIntelligenceService.normalizeMerchant('ATM $loc');
        return (normalized, ConfidenceTier.high);
      }
      return ('ATM Cash Withdrawal', ConfidenceTier.high);
    }

    // Priority 8: Contextual Merchant Fallback (Never raw SMS sender header)
    final upperSender = sender.toUpperCase();
    if (upperSender.contains('AIRTEL') || lower.contains('airtel')) {
      return ('Airtel Recharge', ConfidenceTier.medium);
    }
    if (upperSender.contains('JIO') || lower.contains('jio')) {
      return ('Jio Recharge', ConfidenceTier.medium);
    }
    if (upperSender.contains('VI') ||
        upperSender.contains('VODAFONE') ||
        lower.contains('vodafone')) {
      return ('Vi Recharge', ConfidenceTier.medium);
    }
    if (upperSender.contains('BSNL') || lower.contains('bsnl')) {
      return ('BSNL Recharge', ConfidenceTier.medium);
    }

    if (lower.contains('recharge')) {
      return ('Mobile Recharge', ConfidenceTier.medium);
    }
    if (lower.contains('upi') || lower.contains('vpa')) {
      return ('UPI Transfer', ConfidenceTier.medium);
    }
    if (lower.contains('neft') || lower.contains('imps')) {
      return ('Bank Transfer', ConfidenceTier.medium);
    }
    if (lower.contains('card') || lower.contains('pos')) {
      return ('Card Purchase', ConfidenceTier.medium);
    }

    return ('Bank Transfer', ConfidenceTier.low);
  }

  static String _detectCategoryFromText(String lowerText, String merchant) {
    final mLower = merchant.toLowerCase();
    if (mLower.contains('swiggy') ||
        mLower.contains('zomato') ||
        lowerText.contains('food') ||
        lowerText.contains('restaurant') ||
        lowerText.contains('dining') ||
        lowerText.contains('dominos') ||
        lowerText.contains('mcdonald')) return 'Food';
    if (mLower.contains('petrol') ||
        mLower.contains('fuel') ||
        mLower.contains('indian oil') ||
        mLower.contains('hpcl') ||
        mLower.contains('bpcl')) return 'Fuel';
    if (mLower.contains('google one') ||
        mLower.contains('youtube premium') ||
        mLower.contains('netflix') ||
        mLower.contains('spotify') ||
        mLower.contains('prime') ||
        mLower.contains('hotstar') ||
        mLower.contains('chatgpt') ||
        mLower.contains('apple')) return 'Subscriptions';
    if (mLower.contains('airtel') ||
        mLower.contains('jio') ||
        mLower.contains('fiber') ||
        mLower.contains('broadband') ||
        mLower.contains('electricity') ||
        mLower.contains('bescom') ||
        mLower.contains('bill') ||
        lowerText.contains('bill')) return 'Bills';
    if (mLower.contains('uber') ||
        mLower.contains('ola') ||
        mLower.contains('rapido') ||
        mLower.contains('irctc') ||
        mLower.contains('metro')) return 'Travel';
    if (mLower.contains('amazon') ||
        mLower.contains('flipkart') ||
        mLower.contains('myntra') ||
        mLower.contains('zepto') ||
        mLower.contains('blinkit') ||
        mLower.contains('bigbasket') ||
        mLower.contains('reliance')) return 'Shopping';
    if (mLower.contains('salary') || lowerText.contains('salary credited')) {
      return 'Salary';
    }
    if (mLower.contains('atm') || lowerText.contains('cash withdrawal')) {
      return 'Cash';
    }
    if (mLower.contains('emi') ||
        mLower.contains('rent') ||
        lowerText.contains('emi deduction')) return 'EMI';
    return 'General';
  }

  static String? _extractAccount(String body) {
    final match = _accountRegex.firstMatch(body);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
}
