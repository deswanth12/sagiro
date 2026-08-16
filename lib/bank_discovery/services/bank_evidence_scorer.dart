import '../../services/sms_parser.dart';
import '../models/discovered_bank.dart';

class RawSmsData {
  final int? id;
  final String sender;
  final String body;
  final DateTime date;

  RawSmsData({
    this.id,
    required this.sender,
    required this.body,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'body': body,
      'date': date.toIso8601String(),
    };
  }

  factory RawSmsData.fromMap(Map<String, dynamic> map) {
    return RawSmsData(
      id: map['id'] as int?,
      sender: map['sender'] as String? ?? '',
      body: map['body'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class BankEvidenceResult {
  final List<DiscoveredBank> discoveredBanks;
  final int processedCount;
  final int financialCount;
  final int? maxSmsId;
  final DateTime? maxTimestamp;

  BankEvidenceResult({
    required this.discoveredBanks,
    required this.processedCount,
    required this.financialCount,
    this.maxSmsId,
    this.maxTimestamp,
  });
}

class BankEvidenceScorer {
  static const List<String> _balanceKeywords = [
    'avail bal',
    'available balance',
    'a/c bal',
    'ac bal',
    'ledger bal',
    'clear bal',
    'total balance',
    'bal is rs',
    'bal rs',
    'bal: rs',
    'bal in a/c',
    'curr bal',
  ];

  static const List<String> _nonFinancialKeywords = [
    'otp',
    'one time password',
    'verification code',
    'security code',
    'secret code',
    'login code',
    'auth code',
    'do not share',
    'don\'t share',
    'never share',
    'pre-approved',
    'apply now',
    'click to claim',
    'congratulations',
    'discount',
    'offer valid',
    'instant loan',
    'personal loan offer',
    'credit limit enhancement',
  ];

  /// Core scoring method executed on worker isolate via compute()
  static Map<String, dynamic> scoreBatchIsolate(
      List<Map<String, dynamic>> batchDataList) {
    final batch = batchDataList.map((m) => RawSmsData.fromMap(m)).toList();
    final result = scoreBatch(batch);

    return {
      'discoveredBanks': result.discoveredBanks.map((b) => b.toMap()).toList(),
      'processedCount': result.processedCount,
      'financialCount': result.financialCount,
      'maxSmsId': result.maxSmsId,
      'maxTimestamp': result.maxTimestamp?.toIso8601String(),
    };
  }

  static BankEvidenceResult scoreBatch(List<RawSmsData> messages) {
    final Map<String, _BankAccumulator> accumulators = {};
    int financialCount = 0;
    int? maxId;
    DateTime? maxDate;
    final now = DateTime.now();

    for (final msg in messages) {
      if (msg.id != null && (maxId == null || msg.id! > maxId)) {
        maxId = msg.id;
      }
      if (maxDate == null || msg.date.isAfter(maxDate)) {
        maxDate = msg.date;
      }

      final normalizedSender = msg.sender.trim().toUpperCase();
      final bodyLower = msg.body.toLowerCase();

      // Filter 1: Check non-financial OTP / Marketing (Zero Points)
      if (_isNonFinancial(bodyLower)) {
        continue;
      }

      // Filter 2: Check sender against SmsParser 71-bank registry
      final bankInfo = _identifyBankFromSender(normalizedSender, msg.body);
      if (bankInfo == null) {
        continue;
      }

      final bankCode = bankInfo['code']!;
      final bankName = bankInfo['name']!;

      final acc = accumulators.putIfAbsent(
        bankCode,
        () => _BankAccumulator(bankCode: bankCode, bankName: bankName),
      );

      // Analyze SMS body for financial evidence
      final parseResult = SmsParser.parseSmsDetailed(msg.body, msg.sender);
      final isBalanceMsg = _isBalanceSms(bodyLower);

      if (parseResult != null &&
          (parseResult.confidenceTier == ConfidenceTier.high ||
              parseResult.confidenceTier == ConfidenceTier.medium)) {
        acc.confirmedTxCount++;
        acc.distinctDays
            .add(DateTime(msg.date.year, msg.date.month, msg.date.day));
        if (parseResult.transaction.account != null &&
            parseResult.transaction.account!.isNotEmpty) {
          acc.accountLast4Set.add(parseResult.transaction.account!);
        }
        financialCount++;
      } else if (isBalanceMsg) {
        acc.balanceCount++;
        acc.distinctDays
            .add(DateTime(msg.date.year, msg.date.month, msg.date.day));
        financialCount++;
      } else {
        // Light financial indicator
        acc.generalActivityCount++;
      }

      // Track timestamps
      if (acc.firstSeen == null || msg.date.isBefore(acc.firstSeen!)) {
        acc.firstSeen = msg.date;
      }
      if (acc.lastSeen == null || msg.date.isAfter(acc.lastSeen!)) {
        acc.lastSeen = msg.date;
      }
    }

    // Build & score final DiscoveredBank models
    final List<DiscoveredBank> discoveredList = [];

    for (final entry in accumulators.entries) {
      final acc = entry.value;

      double score = 0.0;

      // 1. Confirmed Transactions: +25 pts each
      score += (acc.confirmedTxCount * 25.0);

      // 2. Balance / Account activity: +20 pts each
      score += (acc.balanceCount * 20.0);

      // 3. Account ID extracted: +15 pts per unique last 4 digits
      score += (acc.accountLast4Set.length * 15.0);

      // 4. Repeated activity (3+ distinct days): +15 pts
      if (acc.distinctDays.length >= 3) {
        score += 15.0;
      }

      // 5. Recency Bonus: +10 pts if active in last 30 days
      if (acc.lastSeen != null && now.difference(acc.lastSeen!).inDays <= 30) {
        score += 10.0;
      }

      // General activity cap: +2 pts each (max 10)
      score += (acc.generalActivityCount * 2.0).clamp(0.0, 10.0);

      // Determine confidence level
      BankConfidenceLevel confidenceLevel;
      if (score >= 50.0 &&
          (acc.accountLast4Set.isNotEmpty || acc.confirmedTxCount >= 2)) {
        confidenceLevel = BankConfidenceLevel.high;
      } else if (score >= 25.0) {
        confidenceLevel = BankConfidenceLevel.medium;
      } else if (score >= 10.0) {
        confidenceLevel = BankConfidenceLevel.low;
      } else {
        confidenceLevel = BankConfidenceLevel.unknown;
      }

      if (confidenceLevel != BankConfidenceLevel.unknown) {
        discoveredList.add(DiscoveredBank(
          bankName: acc.bankName,
          bankCode: acc.bankCode,
          confidenceLevel: confidenceLevel,
          evidenceScore: score,
          confirmedTransactionCount: acc.confirmedTxCount,
          balanceActivityCount: acc.balanceCount,
          accountLast4Set: acc.accountLast4Set.toList(),
          firstSeenDate: acc.firstSeen ?? now,
          lastSeenDate: acc.lastSeen ?? now,
        ));
      }
    }

    // Rank banks by evidenceScore descending
    discoveredList.sort((a, b) => b.evidenceScore.compareTo(a.evidenceScore));

    // Assign Primary & Secondary status
    final List<DiscoveredBank> ranked = [];
    for (int i = 0; i < discoveredList.length; i++) {
      final bank = discoveredList[i];
      ranked.add(bank.copyWith(
        isPrimary: i == 0 && bank.evidenceScore >= 25.0,
        isSecondary: i == 1 && bank.evidenceScore >= 20.0,
      ));
    }

    return BankEvidenceResult(
      discoveredBanks: ranked,
      processedCount: messages.length,
      financialCount: financialCount,
      maxSmsId: maxId,
      maxTimestamp: maxDate,
    );
  }

  static bool _isNonFinancial(String bodyLower) {
    for (final kw in _nonFinancialKeywords) {
      if (bodyLower.contains(kw)) return true;
    }
    return false;
  }

  static bool _isBalanceSms(String bodyLower) {
    for (final kw in _balanceKeywords) {
      if (bodyLower.contains(kw)) return true;
    }
    return false;
  }

  static Map<String, String>? _identifyBankFromSender(
      String sender, String body) {
    final senderUpper = sender.trim().toUpperCase();

    for (final entry in SmsParser.financialSendersIndia.entries) {
      final bankName = entry.key;
      final codes = entry.value;

      for (final code in codes) {
        final codeUpper = code.toUpperCase();
        if (senderUpper.contains(codeUpper) ||
            senderUpper.endsWith(codeUpper)) {
          return {
            'code': codeUpper,
            'name': bankName,
          };
        }
      }
    }

    // Fallback search in body for bank names if sender header is generic
    final bodyUpper = body.toUpperCase();
    if (bodyUpper.contains('HDFC BANK')) {
      return {'code': 'HDFCBK', 'name': 'HDFC Bank'};
    }
    if (bodyUpper.contains('STATE BANK OF INDIA') ||
        bodyUpper.contains('SBI')) {
      return {'code': 'SBIINB', 'name': 'State Bank of India'};
    }
    if (bodyUpper.contains('ICICI BANK')) {
      return {'code': 'ICICIB', 'name': 'ICICI Bank'};
    }
    if (bodyUpper.contains('AXIS BANK')) {
      return {'code': 'AXISBK', 'name': 'Axis Bank'};
    }
    if (bodyUpper.contains('KOTAK BANK') ||
        bodyUpper.contains('KOTAK MAHINDRA')) {
      return {'code': 'KOTAKB', 'name': 'Kotak Mahindra Bank'};
    }
    if (bodyUpper.contains('PUNJAB NATIONAL BANK') ||
        bodyUpper.contains('PNB')) {
      return {'code': 'PNBSMS', 'name': 'Punjab National Bank'};
    }
    if (bodyUpper.contains('BANK OF BARODA') || bodyUpper.contains('BOB')) {
      return {'code': 'BOBIMT', 'name': 'Bank of Baroda'};
    }
    if (bodyUpper.contains('CANARA BANK')) {
      return {'code': 'CANBNK', 'name': 'Canara Bank'};
    }
    if (bodyUpper.contains('UNION BANK')) {
      return {'code': 'UNIONBK', 'name': 'Union Bank of India'};
    }
    if (bodyUpper.contains('PAYTM PAYMENTS BANK') ||
        bodyUpper.contains('PAYTM BANK')) {
      return {'code': 'PAYTMB', 'name': 'Paytm Payments Bank'};
    }

    return null;
  }
}

class _BankAccumulator {
  final String bankCode;
  final String bankName;
  int confirmedTxCount = 0;
  int balanceCount = 0;
  int generalActivityCount = 0;
  final Set<String> accountLast4Set = {};
  final Set<DateTime> distinctDays = {};
  DateTime? firstSeen;
  DateTime? lastSeen;

  _BankAccumulator({
    required this.bankCode,
    required this.bankName,
  });
}
