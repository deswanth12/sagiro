/// Explicit Classification Types for incoming SMS messages
enum SmsClassification {
  financialTransaction,
  otp,
  promotional,
  delivery,
  securityAlert,
  personal,
  spam,
  unknown,
}

/// Structured outcome of first-stage cheap SMS classification
class SmsClassificationResult {
  final SmsClassification classification;
  final int confidenceScore; // 0 - 100%
  final List<String> reasons;
  final bool isCandidateForParsing;

  const SmsClassificationResult({
    required this.classification,
    required this.confidenceScore,
    this.reasons = const [],
    required this.isCandidateForParsing,
  });

  bool get isFinancial =>
      classification == SmsClassification.financialTransaction;
  bool get isOtp => classification == SmsClassification.otp;
  bool get isPromotional => classification == SmsClassification.promotional;
  bool get isDelivery => classification == SmsClassification.delivery;
  bool get isSecurityAlert => classification == SmsClassification.securityAlert;
  bool get isPersonal => classification == SmsClassification.personal;
  bool get isSpam => classification == SmsClassification.spam;
  bool get isUnknown => classification == SmsClassification.unknown;

  @override
  String toString() =>
      'SmsClassificationResult(classification: $classification, confidence: $confidenceScore%, reasons: $reasons)';
}

/// SmsClassifier — Fast, lightweight, zero-allocation pre-classifier.
/// Filters out non-financial messages in < 0.05ms before expensive parsing.
class SmsClassifier {
  // ── 1. OTP & Verification Overrides (Highest Priority) ─────────────────────
  static final RegExp _otpRegex = RegExp(
    r'\b(?:otp|one[- ]time\s+(?:password|pin)|verification\s+code|secret\s+code|auth(?:orization)?\s+code|login\s+code|security\s+code)\b',
    caseSensitive: false,
  );

  static final RegExp _otpActionRegex = RegExp(
    r'\b(?:is\s+your\s+(?:secret\s+)?otp|do\s+not\s+share|never\s+share|valid\s+for\s+\d+\s*(?:mins?|minutes?|secs?|seconds?)|use\s+\d{4,8}\s+to\s+verify|valid\s+till|to\s+authenticate)\b',
    caseSensitive: false,
  );

  // ── 2. Spam & Scam Patterns ────────────────────────────────────────────────
  static final RegExp _spamRegex = RegExp(
    r'\b(?:congratulations!?(?:\s+you)?\s+won|lucky\s+winner|claim\s+your\s+(?:reward|prize|cash|gift)|you\s+have\s+won|lottery|jackpot|selected\s+for\s+cash\s+prize|spin\s+and\s+win)\b',
    caseSensitive: false,
  );

  // ── 3. Promotional & Marketing Overrides ──────────────────────────────────
  static final RegExp _promotionalStrongRegex = RegExp(
    r'\b(?:apply\s+(?:now|today|for)|get\s+(?:instant\s+)?loan|pre[- ]approved|eligible\s+for\s+(?:loan|card|limit)|personal\s+loan\s+up\s+to|increase\s+credit\s+limit|credit\s+limit\s+(?:is\s+)?(?:increased|enhanced)|lifetime[- ]free\s+credit\s+card|get\s+a\s+new\s+credit\s+card|upgrade\s+your\s+(?:[A-Za-z0-9\s]+\s+)?card|credit\s+card\s+offer)\b',
    caseSensitive: false,
  );

  static final RegExp _promotionalOffersRegex = RegExp(
    r'\b(?:special\s+offer|flat\s+discount|use\s+coupon|cashback\s+offer|exclusive\s+offer|get\s+\d+%\s+cashback|shop\s+now\s+and\s+save|win\s*(?:rs\.?|inr|₹)\s*\d+|get\s*(?:rs\.?|inr|₹)\s*\d+\s+cashback|loan\s+available\s+up\s+to|shop\s+for\s*(?:rs\.?|inr|₹)\s*\d+|earn\s+reward\s+points|redeem\s+your\s+(?:cashback|points|reward)|avail\s+offer|hurry|limited\s+period\s+offer|bumper\s+sale|mega\s+sale|discount\s+voucher)\b',
    caseSensitive: false,
  );

  static final RegExp _telecomMarketingRegex = RegExp(
    r'\b(?:recharge\s+(?:now\s+and\s+get|and\s+get|with|for)\s*(?:rs\.?|inr|₹)?\s*\d+\s*(?:and|to)\s*get|extra\s+data|unlimited\s+calls?\s*(?:&|and)\s*data\s+offer|special\s+(?:airtel|jio|vi|bsnl)\s+offer|data\s+pack\s+offer|talktime\s+offer|recharge\s+offer)\b',
    caseSensitive: false,
  );

  // ── 4. Delivery & Order Notifications ─────────────────────────────────────
  static final RegExp _deliveryRegex = RegExp(
    r'\b(?:out\s+for\s+delivery|order\s+(?:has\s+)?(?:dispatched|delivered|placed|confirmed|shipped|picked\s+up)|has\s+shipped|arriving\s+(?:today|tomorrow|by)|package\s+(?:delivered|arrived|is|shipped)|delivery\s+partner|tracking\s+(?:id|link|number)|shipment|awb|courier\s+partner)\b',
    caseSensitive: false,
  );

  // ── 5. Security & Account Alerts ──────────────────────────────────────────
  static final RegExp _securityAlertRegex = RegExp(
    r'\b(?:login\s+detected|logged\s+in\s+from|new\s+device\s+login|password\s+changed|update\s+your\s+kyc|kyc\s+(?:pending|suspended|expired|update|verification)|pan\s+linked|sim\s+swap|unrecognized\s+device|pin\s+changed)\b',
    caseSensitive: false,
  );

  // ── 6. Strong Financial Transaction Signals (Completed Past Actions) ───────
  static final RegExp _financialActionRegex = RegExp(
    r'\b(?:debited|credited|withdrawn|transferred|deposited|charged|spent|paid|sent|received|refunded|reversed|salary\s+credited|cash\s+withdrawal|atm\s+(?:wdl|withdrawal)|emi\s+(?:deduction|deducted)|pos\s+purchase|upi\s+(?:payment|transfer)|imps\s+transfer|neft\s+transfer|auto[- ]debited|mandate\s+executed|paid\s+to|received\s+from|payment\s+of\s*(?:rs\.?|inr|₹)|payment\s+received|recharge\s+(?:is\s+)?successful|recharge\s+(?:of\s*)?(?:rs\.?|inr|₹)?\s*[\d,.]+\s*(?:is\s+)?successful|payment\s+(?:is\s+)?successful|plan\s+(?:name\s*)?:)\b',
    caseSensitive: false,
  );

  static final RegExp _amountPatternRegex = RegExp(
    r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)|([\d,]+(?:\.\d{1,2})?)\s*(?:rs\.?|inr|₹)|(?:plan\s*(?:name|price|amt|amount)?|mrp|pack)\s*:\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _accountPatternRegex = RegExp(
    r'\b(?:a/c|acct|account|card|jio\s*number|mobile\s*no|mobile\s*number|phone\s*no)\s*(?:no\.?)?\s*[:#\s]*[xX\*]*(\d{3,10})\b',
    caseSensitive: false,
  );

  static final RegExp _referencePatternRegex = RegExp(
    r'\b(?:ref|rrn|utr|txn\s*id|txn\s*ref|upi\s*ref|reference|imps\s*ref|transaction\s*id)\b',
    caseSensitive: false,
  );

  static final RegExp _conversationalPersonalRegex = RegExp(
    r'\b(?:hi|hello|hey|where\s+are\s+you|call\s+me|call\s+back|ok|okay|thanks|good\s+morning|good\s+night|see\s+you|how\s+are\s+you|happy\s+birthday)\b',
    caseSensitive: false,
  );

  /// Primary Fast Classification Method
  static SmsClassificationResult classify(String body, String sender) {
    if (body.isEmpty) {
      return const SmsClassificationResult(
        classification: SmsClassification.unknown,
        confidenceScore: 0,
        reasons: ['Empty message body'],
        isCandidateForParsing: false,
      );
    }

    final lower = body.toLowerCase().trim();
    final reasons = <String>[];

    // ── STAGE 1: Immediate Safety Overrides ─────────────────────────────────

    // 1. OTP Override: OTPs MUST NEVER become financial transactions
    if (_otpRegex.hasMatch(lower) || _otpActionRegex.hasMatch(lower)) {
      return const SmsClassificationResult(
        classification: SmsClassification.otp,
        confidenceScore: 99,
        reasons: ['OTP / Verification code detected'],
        isCandidateForParsing: false,
      );
    }

    // 2. Security Alerts: KYC, Login, Password alerts
    if (_securityAlertRegex.hasMatch(lower)) {
      return const SmsClassificationResult(
        classification: SmsClassification.securityAlert,
        confidenceScore: 95,
        reasons: ['Account security alert / KYC notification'],
        isCandidateForParsing: false,
      );
    }

    // 3. Spam / Lottery / Fake Prize
    if (_spamRegex.hasMatch(lower)) {
      return const SmsClassificationResult(
        classification: SmsClassification.spam,
        confidenceScore: 95,
        reasons: ['Lottery / Spam reward / Prize scam pattern'],
        isCandidateForParsing: false,
      );
    }

    // 4. Delivery & Shipment Alerts (without explicit payment debit/credit)
    if (_deliveryRegex.hasMatch(lower) &&
        !lower.contains('debited') &&
        !lower.contains('credited') &&
        !lower.contains('charged') &&
        !lower.contains('paid rs') &&
        !lower.contains('spent rs')) {
      return const SmsClassificationResult(
        classification: SmsClassification.delivery,
        confidenceScore: 90,
        reasons: ['Package shipment or delivery notification'],
        isCandidateForParsing: false,
      );
    }

    // ── STAGE 2: Promotional / Marketing Analysis ───────────────────────────
    final isPromoOffer = _promotionalOffersRegex.hasMatch(lower);
    final isPromoStrong = _promotionalStrongRegex.hasMatch(lower);
    final isTelecomPromo = _telecomMarketingRegex.hasMatch(lower);

    // Check if there is an actual completed financial event
    final hasFinancialAction = _financialActionRegex.hasMatch(lower);
    final hasAmount = _amountPatternRegex.hasMatch(lower);
    final hasAccount = _accountPatternRegex.hasMatch(lower);
    final hasReference = _referencePatternRegex.hasMatch(lower);

    // If strong promotional markers exist without clear completed debited/credited event
    if (isPromoStrong || isPromoOffer || isTelecomPromo) {
      // Completed recharge or payment exception: "Recharge of Rs 299 is successful"
      final isCompletedRecharge = lower.contains('successful') &&
          (lower.contains('recharge of') ||
              lower.contains('payment of') ||
              lower.contains('paid'));

      if (!hasFinancialAction && !isCompletedRecharge) {
        return SmsClassificationResult(
          classification: SmsClassification.promotional,
          confidenceScore: 90,
          reasons: [
            if (isPromoStrong) 'Loan / Credit card offer',
            if (isPromoOffer) 'Discount / Cashback advertisement',
            if (isTelecomPromo) 'Telecom promotional offer',
          ],
          isCandidateForParsing: false,
        );
      }
    }

    // ── STAGE 3: Financial Transaction Scoring ──────────────────────────────
    if (hasFinancialAction || (hasAmount && hasAccount)) {
      int score = 0;

      if (hasFinancialAction) {
        score += 40;
        reasons.add('Completed financial action verb (+40)');
      }

      if (hasAmount) {
        score += 20;
        reasons.add('Currency amount detected (+20)');
      }

      if (hasAccount) {
        score += 15;
        reasons.add('Bank account / card identifier (+15)');
      }

      if (hasReference) {
        score += 15;
        reasons.add('Transaction UTR / RRN / Ref reference (+15)');
      }

      // Check merchant context
      if (lower.contains('at ') ||
          lower.contains('to ') ||
          lower.contains('vpa') ||
          lower.contains('info/') ||
          lower.contains('towards')) {
        score += 10;
        reasons.add('Merchant / Payee context (+10)');
      }

      // Penalties for promotional noise
      if (isPromoOffer || isTelecomPromo) {
        score -= 35;
        reasons.add('Promotional keyword penalty (-35)');
      }

      if (lower.contains('offer') ||
          lower.contains('cashback') ||
          lower.contains('win') ||
          lower.contains('discount')) {
        score -= 20;
        reasons.add('Marketing word penalty (-20)');
      }

      // If score is high (>= 50), it is a qualified Financial Transaction Candidate
      if (score >= 50 &&
          (hasFinancialAction || (hasAmount && hasAccount && hasReference))) {
        return SmsClassificationResult(
          classification: SmsClassification.financialTransaction,
          confidenceScore: score.clamp(0, 100),
          reasons: reasons,
          isCandidateForParsing: true,
        );
      } else if (score >= 35) {
        // Needs review / possible promotional
        return SmsClassificationResult(
          classification: SmsClassification.promotional,
          confidenceScore: score.clamp(0, 100),
          reasons: [
            ...reasons,
            'Low confidence financial signal with promotional overlap'
          ],
          isCandidateForParsing: false,
        );
      }
    }

    // ── STAGE 4: Personal Conversational SMS ─────────────────────────────────
    if (_conversationalPersonalRegex.hasMatch(lower) &&
        !hasAmount &&
        !hasAccount) {
      return const SmsClassificationResult(
        classification: SmsClassification.personal,
        confidenceScore: 85,
        reasons: ['Conversational personal text'],
        isCandidateForParsing: false,
      );
    }

    // ── STAGE 5: Default Unknown (Filtered, NOT a transaction) ───────────────
    return const SmsClassificationResult(
      classification: SmsClassification.unknown,
      confidenceScore: 20,
      reasons: ['No financial transaction signals detected'],
      isCandidateForParsing: false,
    );
  }
}
