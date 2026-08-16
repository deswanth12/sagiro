import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';
import '../models/canonical_transaction_identity.dart';
import 'database_helper.dart';
import 'sms_classifier.dart';
import 'sms_parser.dart';

class SmsInboxService {
  static final SmsInboxService instance = SmsInboxService._();
  SmsInboxService._();

  /// Check if READ_SMS permission is granted
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.sms.status;
    if (kDebugMode) {
      debugPrint(
          '[SMS Scan] Stage 1 & 2: Permission status=$status, isGranted=${status.isGranted}');
    }
    return status.isGranted;
  }

  /// Request SMS permission at runtime
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.sms.request();
    if (kDebugMode) {
      debugPrint(
          '[SMS Scan] Stage 1 & 2: Permission request status=$status, isGranted=${status.isGranted}');
    }
    return status.isGranted;
  }

  /// Check if SMS permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    if (kIsWeb) return false;
    final status = await Permission.sms.status;
    return status.isPermanentlyDenied;
  }

  /// Read all bank SMS from inbox and parse into transactions.
  Future<SmsReadResult> readAndParseBankSms({
    List<String> existingReferences = const [],
    List<String> existingFingerprints = const [],
    String profileId = 'default_profile',
    int maxMessages = 500,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    if (kIsWeb) {
      return const SmsReadResult(
        transactions: [],
        parsedItems: [],
        totalRead: 0,
        totalInboxMessages: 0,
        passedToParser: 0,
        rejectedKeyword: 0,
        parsed: 0,
        debitCount: 0,
        creditCount: 0,
        skippedDuplicates: 0,
        needsReviewCount: 0,
        readyToAddCount: 0,
        permissionDenied: false,
        webUnsupported: true,
      );
    }

    final granted = await hasPermission();
    if (!granted) {
      final permDenied = await isPermissionPermanentlyDenied();
      return SmsReadResult(
        transactions: [],
        parsedItems: [],
        totalRead: 0,
        totalInboxMessages: 0,
        passedToParser: 0,
        rejectedKeyword: 0,
        parsed: 0,
        debitCount: 0,
        creditCount: 0,
        skippedDuplicates: 0,
        needsReviewCount: 0,
        readyToAddCount: 0,
        permissionDenied: true,
        permanentlyDenied: permDenied,
      );
    }

    try {
      if (kDebugMode) {
        debugPrint(
            '[SMS Scan] Stage 3: SMS inbox query starting (count limit: $maxMessages)...');
      }
      onProgress?.call(0, 0, 'Reading SMS inbox…');
      final query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: maxMessages,
      );
      if (kDebugMode) {
        debugPrint(
            '[SMS Scan] Stage 4: SMS query returned ${messages.length} inbox messages.');
      }

      int passedToParser = 0;
      int rejectedKeyword = 0;
      int skippedDuplicates = 0;
      int debitCount = 0;
      int creditCount = 0;
      int needsReviewCount = 0;
      int readyToAddCount = 0;

      // Red-Team Classification Metric Counters
      int otpRejected = 0;
      int promotionalRejected = 0;
      int deliveryRejected = 0;
      int securityRejected = 0;
      int spamRejected = 0;
      int personalRejected = 0;
      int unknownRejected = 0;

      final parsedList = <TransactionItem>[];
      final parsedItems = <SmsParsedItem>[];

      // Preload all existing fingerprints and reference IDs directly from SQLite
      final dbFingerprints = await DatabaseHelper.instance
          .getAllExistingFingerprints(profileId: profileId);

      // Average O(1) lookup set for normalized transaction references
      final refSet = {
        ...dbFingerprints.map((r) => r.trim().toLowerCase()),
        ...existingReferences.map((r) => r.trim().toLowerCase()),
      }..removeWhere((r) => r.isEmpty);

      // Average O(1) lookup set for deterministic fingerprints
      final fingerprintSet = {
        ...dbFingerprints.map((f) => f.trim().toLowerCase()),
        ...existingFingerprints.map((f) => f.trim().toLowerCase()),
      }..removeWhere((f) => f.isEmpty);

      for (int i = 0; i < messages.length; i++) {
        final sms = messages[i];
        if (i % 15 == 0 || i == messages.length - 1) {
          onProgress?.call(
            i + 1,
            messages.length,
            'Scanning ${i + 1} / ${messages.length} messages…',
          );
          // Yield to UI thread to ensure zero frame drop
          await Future.delayed(Duration.zero);
        }

        final body = sms.body ?? '';
        final sender = sms.sender ?? '';
        if (body.isEmpty) continue;

        // Stage 1: Fast Cheap SMS Classification
        final classification = SmsClassifier.classify(body, sender);
        if (!classification.isCandidateForParsing) {
          rejectedKeyword++;
          switch (classification.classification) {
            case SmsClassification.otp:
              otpRejected++;
              break;
            case SmsClassification.promotional:
              promotionalRejected++;
              break;
            case SmsClassification.delivery:
              deliveryRejected++;
              break;
            case SmsClassification.securityAlert:
              securityRejected++;
              break;
            case SmsClassification.spam:
              spamRejected++;
              break;
            case SmsClassification.personal:
              personalRejected++;
              break;
            case SmsClassification.unknown:
            default:
              unknownRejected++;
              break;
          }
          continue;
        }

        // Stage 2: Message passed to parser as confirmed candidate
        passedToParser++;
        final date = sms.date ?? DateTime.now();
        final result = SmsParser.parseSmsDetailed(body, sender, smsDate: date);
        if (result == null) {
          rejectedKeyword++;
          unknownRejected++;
          continue;
        }

        // Stage 3: Successfully parsed
        final sourceId = sms.id?.toString();
        var tx = result.transaction.copyWith(
          profileId: profileId,
          sourceMessageId: sourceId,
        );

        // Compute deterministic canonical fingerprint
        final fingerprint = CanonicalTransactionIdentity.computeFingerprint(tx);
        tx = tx.copyWith(transactionFingerprint: fingerprint);

        // Duplicate Detection via Reference and Fingerprint (O(1) lookups)
        final ref = tx.transactionReference?.trim().toLowerCase();
        final bool refMatches =
            ref != null && ref.isNotEmpty && refSet.contains(ref);
        final bool fingerprintMatches =
            fingerprintSet.contains(fingerprint.toLowerCase());

        if (refMatches || fingerprintMatches) {
          skippedDuplicates++;
          if (kDebugMode) {
            debugPrint(
                '[SMS Scan] Skipped duplicate: ref=$ref, fp=$fingerprint');
          }
          continue;
        }

        if (ref != null && ref.isNotEmpty) {
          refSet.add(ref);
        }
        fingerprintSet.add(fingerprint.toLowerCase());

        if (tx.type == TransactionType.debit) {
          debitCount++;
        } else {
          creditCount++;
        }

        if (result.needsReview) {
          needsReviewCount++;
        } else {
          readyToAddCount++;
        }

        parsedList.add(tx);
        parsedItems.add(SmsParsedItem(
          transaction: tx,
          result: result,
          fingerprint: fingerprint,
        ));
      }

      if (kDebugMode) {
        debugPrint(
            '[SMS Scan] Summary — Read: ${messages.length}, Candidates: $passedToParser, OTP Rejected: $otpRejected, Promo Rejected: $promotionalRejected, Delivery Rejected: $deliveryRejected, Security Rejected: $securityRejected, Spam Rejected: $spamRejected, Personal Rejected: $personalRejected, Unknown Rejected: $unknownRejected, Parsed: ${parsedList.length} (Debits: $debitCount, Credits: $creditCount), Duplicates Skipped: $skippedDuplicates');
      }

      return SmsReadResult(
        transactions: parsedList,
        parsedItems: parsedItems,
        totalRead: passedToParser,
        totalInboxMessages: messages.length,
        passedToParser: passedToParser,
        rejectedKeyword: rejectedKeyword,
        parsed: parsedList.length,
        debitCount: debitCount,
        creditCount: creditCount,
        skippedDuplicates: skippedDuplicates,
        needsReviewCount: needsReviewCount,
        readyToAddCount: readyToAddCount,
        permissionDenied: false,
        otpRejected: otpRejected,
        promotionalRejected: promotionalRejected,
        deliveryRejected: deliveryRejected,
        securityRejected: securityRejected,
        spamRejected: spamRejected,
        personalRejected: personalRejected,
        unknownRejected: unknownRejected,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SMS Scan] SmsInboxService error: $e');
      }
      return SmsReadResult(
        transactions: [],
        parsedItems: [],
        totalRead: 0,
        totalInboxMessages: 0,
        passedToParser: 0,
        rejectedKeyword: 0,
        parsed: 0,
        debitCount: 0,
        creditCount: 0,
        skippedDuplicates: 0,
        needsReviewCount: 0,
        readyToAddCount: 0,
        permissionDenied: false,
        error: e.toString(),
      );
    }
  }

  /// Real-time SMS Stream Subscription from Native SmsReceiver.kt
  StreamSubscription? _smsStreamSub;

  void listenToIncomingSms(Function(TransactionItem tx) onNewTransaction) {
    if (kIsWeb) return;
    try {
      const smsChannel = EventChannel('com.deshu.sagiro.app/sms_stream');
      _smsStreamSub?.cancel();
      _smsStreamSub =
          smsChannel.receiveBroadcastStream().listen((dynamic event) {
        if (event is Map) {
          final sender = event['sender']?.toString() ?? '';
          final body = event['body']?.toString() ?? '';
          if (body.isNotEmpty) {
            final parsed =
                SmsParser.parseSms(body, sender, smsDate: DateTime.now());
            if (parsed != null) {
              onNewTransaction(parsed);
            }
          }
        }
      }, onError: (err) {
        debugPrint('SmsStream error: $err');
      });
    } catch (e) {
      debugPrint('Failed to attach real-time SMS listener: $e');
    }
  }

  void stopListeningToIncomingSms() {
    _smsStreamSub?.cancel();
    _smsStreamSub = null;
  }
}

class SmsParsedItem {
  final TransactionItem transaction;
  final SmsParserResult result;
  final String fingerprint;

  const SmsParsedItem({
    required this.transaction,
    required this.result,
    required this.fingerprint,
  });
}

class SmsReadResult {
  final List<TransactionItem> transactions;
  final List<SmsParsedItem> parsedItems;
  final int totalRead;
  final int totalInboxMessages;
  final int passedToParser;
  final int rejectedKeyword;
  final int parsed;
  final int debitCount;
  final int creditCount;
  final int skippedDuplicates;
  final int needsReviewCount;
  final int readyToAddCount;
  final bool permissionDenied;
  final bool permanentlyDenied;
  final bool webUnsupported;
  final String? error;

  // Red-Team Classification Metrics
  final int otpRejected;
  final int promotionalRejected;
  final int deliveryRejected;
  final int securityRejected;
  final int spamRejected;
  final int personalRejected;
  final int unknownRejected;

  const SmsReadResult({
    required this.transactions,
    this.parsedItems = const [],
    required this.totalRead,
    this.totalInboxMessages = 0,
    this.passedToParser = 0,
    this.rejectedKeyword = 0,
    required this.parsed,
    this.debitCount = 0,
    this.creditCount = 0,
    required this.skippedDuplicates,
    this.needsReviewCount = 0,
    this.readyToAddCount = 0,
    required this.permissionDenied,
    this.permanentlyDenied = false,
    this.webUnsupported = false,
    this.error,
    this.otpRejected = 0,
    this.promotionalRejected = 0,
    this.deliveryRejected = 0,
    this.securityRejected = 0,
    this.spamRejected = 0,
    this.personalRejected = 0,
    this.unknownRejected = 0,
  });

  bool get hasError => error != null;
  bool get success =>
      !permissionDenied &&
      !permanentlyDenied &&
      !webUnsupported &&
      error == null;
}
