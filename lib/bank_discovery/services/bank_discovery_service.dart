import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discovered_bank.dart';
import '../models/discovery_checkpoint.dart';
import 'bank_evidence_scorer.dart';

class BankDiscoveryScanResult {
  final List<DiscoveredBank> discoveredBanks;
  final DiscoveredBank? primaryBank;
  final DiscoveredBank? secondaryBank;
  final int totalScannedCount;
  final int totalFinancialCount;
  final int newMessagesScanned;
  final Duration scanDuration;

  BankDiscoveryScanResult({
    required this.discoveredBanks,
    this.primaryBank,
    this.secondaryBank,
    required this.totalScannedCount,
    required this.totalFinancialCount,
    required this.newMessagesScanned,
    required this.scanDuration,
  });
}

class BankDiscoveryService {
  static final BankDiscoveryService instance = BankDiscoveryService._();
  BankDiscoveryService._();

  static const String keyLastProcessedSmsId = 'bank_discovery_last_sms_id';
  static const String keyLastProcessedTimestamp =
      'bank_discovery_last_timestamp';
  static const String keyTotalScannedCount = 'bank_discovery_total_scanned';
  static const String keyLastScanDate = 'bank_discovery_last_scan_date';

  final List<DiscoveredBank> _discoveredBanks = [];
  DiscoveryCheckpoint _checkpoint = DiscoveryCheckpoint();
  bool _isScanning = false;

  List<DiscoveredBank> get discoveredBanks =>
      List.unmodifiable(_discoveredBanks);
  DiscoveryCheckpoint get checkpoint => _checkpoint;
  bool get isScanning => _isScanning;

  DiscoveredBank? get primaryBank {
    try {
      return _discoveredBanks.firstWhere((b) => b.isPrimary);
    } catch (_) {
      return _discoveredBanks.isNotEmpty ? _discoveredBanks.first : null;
    }
  }

  DiscoveredBank? get secondaryBank {
    try {
      return _discoveredBanks.firstWhere((b) => b.isSecondary);
    } catch (_) {
      return _discoveredBanks.length > 1 ? _discoveredBanks[1] : null;
    }
  }

  static const String keyDiscoveredBanks = 'sagiro_discovered_banks_v1';

  Future<void> init() async {
    await loadCheckpoint();
    await loadDiscoveredBanks();
  }

  Future<List<DiscoveredBank>> loadDiscoveredBanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(keyDiscoveredBanks);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _discoveredBanks.clear();
        _discoveredBanks.addAll(
            list.map((m) => DiscoveredBank.fromMap(m as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint('BankDiscoveryService loadDiscoveredBanks error: $e');
    }
    return List.unmodifiable(_discoveredBanks);
  }

  Future<void> saveDiscoveredBanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr =
          jsonEncode(_discoveredBanks.map((b) => b.toMap()).toList());
      await prefs.setString(keyDiscoveredBanks, jsonStr);
    } catch (e) {
      debugPrint('BankDiscoveryService saveDiscoveredBanks error: $e');
    }
  }

  Future<DiscoveryCheckpoint> loadCheckpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt(keyLastProcessedSmsId);
      final lastTsStr = prefs.getString(keyLastProcessedTimestamp);
      final totalScanned = prefs.getInt(keyTotalScannedCount) ?? 0;
      final lastScanStr = prefs.getString(keyLastScanDate);

      _checkpoint = DiscoveryCheckpoint(
        lastProcessedSmsId: lastId,
        lastProcessedTimestamp:
            lastTsStr != null ? DateTime.tryParse(lastTsStr) : null,
        totalScannedCount: totalScanned,
        lastScanDate:
            lastScanStr != null ? DateTime.tryParse(lastScanStr) : null,
      );
    } catch (e) {
      debugPrint('BankDiscoveryService loadCheckpoint error: $e');
    }
    return _checkpoint;
  }

  Future<void> saveCheckpoint(DiscoveryCheckpoint checkpoint) async {
    _checkpoint = checkpoint;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (checkpoint.lastProcessedSmsId != null) {
        await prefs.setInt(
            keyLastProcessedSmsId, checkpoint.lastProcessedSmsId!);
      }
      if (checkpoint.lastProcessedTimestamp != null) {
        await prefs.setString(keyLastProcessedTimestamp,
            checkpoint.lastProcessedTimestamp!.toIso8601String());
      }
      await prefs.setInt(keyTotalScannedCount, checkpoint.totalScannedCount);
      if (checkpoint.lastScanDate != null) {
        await prefs.setString(
            keyLastScanDate, checkpoint.lastScanDate!.toIso8601String());
      }
      await saveDiscoveredBanks();
    } catch (e) {
      debugPrint('BankDiscoveryService saveCheckpoint error: $e');
    }
  }

  /// Perform batched SMS scan and evidence-based bank discovery
  Future<BankDiscoveryScanResult?> scanSmsAndDiscoverBanks({
    int batchSize = 250,
    int maxSmsToScan = 10000,
    List<RawSmsData>? mockMessages, // For unit testing & synthetic 10k dataset
  }) async {
    if (_isScanning) return null;
    _isScanning = true;

    final stopwatch = Stopwatch()..start();

    try {
      List<RawSmsData> allMessages = [];

      if (mockMessages != null) {
        allMessages = mockMessages;
      } else {
        if (!kIsWeb) {
          final status = await Permission.sms.status;
          if (!status.isGranted) {
            final requested = await Permission.sms.request();
            if (!requested.isGranted) {
              _isScanning = false;
              return null;
            }
          }

          final query = SmsQuery();
          final rawSmsList = await query.querySms(
            kinds: [SmsQueryKind.inbox],
            count: maxSmsToScan,
          );

          allMessages = rawSmsList.map((sms) {
            return RawSmsData(
              id: sms.id,
              sender: sms.address ?? '',
              body: sms.body ?? '',
              date: sms.date ?? DateTime.now(),
            );
          }).toList();
        }
      }

      // Checkpoint & Deduplication filtering
      final lastId = _checkpoint.lastProcessedSmsId;
      final lastTs = _checkpoint.lastProcessedTimestamp;

      final Set<String> seenHashes = {};
      final List<RawSmsData> filteredMessages = [];

      for (final msg in allMessages) {
        // Tie-breaker filtering using checkpoint ID & Timestamp
        if (lastId != null && msg.id != null && msg.id! <= lastId) {
          continue;
        }
        if (lastTs != null && msg.date.isBefore(lastTs)) {
          continue;
        }

        final compositeHash =
            '${msg.sender.trim().toUpperCase()}_${msg.date.millisecondsSinceEpoch}_${msg.body.hashCode}';
        if (seenHashes.add(compositeHash)) {
          filteredMessages.add(msg);
        }
      }

      // Process in batches using compute() for CPU offloading
      final List<RawSmsData> allScannedBatch = [];
      int totalFinancial = 0;
      int? maxNewId = lastId;
      DateTime? maxNewTs = lastTs;

      final Map<String, DiscoveredBank> aggregatedBanksMap = {
        for (final b in _discoveredBanks) b.bankCode: b
      };

      for (int i = 0; i < filteredMessages.length; i += batchSize) {
        final endIdx = (i + batchSize < filteredMessages.length)
            ? i + batchSize
            : filteredMessages.length;
        final batch = filteredMessages.sublist(i, endIdx);
        allScannedBatch.addAll(batch);

        BankEvidenceResult batchResult;

        if (kIsWeb || mockMessages != null) {
          // Synchronous execution for web / unit tests
          batchResult = BankEvidenceScorer.scoreBatch(batch);
        } else {
          // Background Worker Isolate via compute()
          final rawMapList = batch.map((m) => m.toMap()).toList();
          final mapResult =
              await compute(BankEvidenceScorer.scoreBatchIsolate, rawMapList);

          final banksList = (mapResult['discoveredBanks'] as List)
              .map((b) => DiscoveredBank.fromMap(b as Map<String, dynamic>))
              .toList();

          batchResult = BankEvidenceResult(
            discoveredBanks: banksList,
            processedCount: mapResult['processedCount'] as int? ?? 0,
            financialCount: mapResult['financialCount'] as int? ?? 0,
            maxSmsId: mapResult['maxSmsId'] as int?,
            maxTimestamp: mapResult['maxTimestamp'] != null
                ? DateTime.tryParse(mapResult['maxTimestamp'] as String)
                : null,
          );
        }

        totalFinancial += batchResult.financialCount;
        if (batchResult.maxSmsId != null &&
            (maxNewId == null || batchResult.maxSmsId! > maxNewId)) {
          maxNewId = batchResult.maxSmsId;
        }
        if (batchResult.maxTimestamp != null &&
            (maxNewTs == null || batchResult.maxTimestamp!.isAfter(maxNewTs))) {
          maxNewTs = batchResult.maxTimestamp;
        }

        // Merge batch results into aggregated map
        for (final bank in batchResult.discoveredBanks) {
          if (aggregatedBanksMap.containsKey(bank.bankCode)) {
            final existing = aggregatedBanksMap[bank.bankCode]!;
            final updatedScore = existing.evidenceScore + bank.evidenceScore;
            final updatedTxCount = existing.confirmedTransactionCount +
                bank.confirmedTransactionCount;
            final updatedBalCount =
                existing.balanceActivityCount + bank.balanceActivityCount;
            final updatedLast4 =
                {...existing.accountLast4Set, ...bank.accountLast4Set}.toList();

            BankConfidenceLevel level;
            if (updatedScore >= 50.0 &&
                (updatedLast4.isNotEmpty || updatedTxCount >= 2)) {
              level = BankConfidenceLevel.high;
            } else if (updatedScore >= 25.0) {
              level = BankConfidenceLevel.medium;
            } else if (updatedScore >= 10.0) {
              level = BankConfidenceLevel.low;
            } else {
              level = BankConfidenceLevel.unknown;
            }

            aggregatedBanksMap[bank.bankCode] = existing.copyWith(
              evidenceScore: updatedScore,
              confirmedTransactionCount: updatedTxCount,
              balanceActivityCount: updatedBalCount,
              accountLast4Set: updatedLast4,
              confidenceLevel: level,
              lastSeenDate: bank.lastSeenDate.isAfter(existing.lastSeenDate)
                  ? bank.lastSeenDate
                  : existing.lastSeenDate,
            );
          } else {
            aggregatedBanksMap[bank.bankCode] = bank;
          }
        }
      }

      final List<DiscoveredBank> finalBankList =
          aggregatedBanksMap.values.toList();
      finalBankList.sort((a, b) => b.evidenceScore.compareTo(a.evidenceScore));

      // Rank Primary & Secondary
      _discoveredBanks.clear();
      for (int i = 0; i < finalBankList.length; i++) {
        final b = finalBankList[i];
        _discoveredBanks.add(b.copyWith(
          isPrimary: i == 0 && b.evidenceScore >= 25.0,
          isSecondary: i == 1 && b.evidenceScore >= 20.0,
        ));
      }

      // Update checkpoint
      final newTotalScanned =
          _checkpoint.totalScannedCount + filteredMessages.length;
      final newCheckpoint = DiscoveryCheckpoint(
        lastProcessedSmsId: maxNewId,
        lastProcessedTimestamp: maxNewTs,
        totalScannedCount: newTotalScanned,
        lastScanDate: DateTime.now(),
      );
      await saveCheckpoint(newCheckpoint);

      stopwatch.stop();

      return BankDiscoveryScanResult(
        discoveredBanks: List.unmodifiable(_discoveredBanks),
        primaryBank: primaryBank,
        secondaryBank: secondaryBank,
        totalScannedCount: newTotalScanned,
        totalFinancialCount: totalFinancial,
        newMessagesScanned: filteredMessages.length,
        scanDuration: stopwatch.elapsed,
      );
    } catch (e) {
      debugPrint('BankDiscoveryService scanSmsAndDiscoverBanks error: $e');
      return null;
    } finally {
      _isScanning = false;
    }
  }

  Future<void> userConfirmBank(String bankCode) async {
    final idx = _discoveredBanks.indexWhere((b) => b.bankCode == bankCode);
    if (idx != -1) {
      _discoveredBanks[idx] =
          _discoveredBanks[idx].copyWith(userConfirmed: true);
      await saveDiscoveredBanks();
    }
  }

  Future<void> userRejectBank(String bankCode) async {
    _discoveredBanks.removeWhere((b) => b.bankCode == bankCode);
    await saveDiscoveredBanks();
  }
}
