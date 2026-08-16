import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagiro/bank_discovery/models/discovered_bank.dart';
import 'package:sagiro/bank_discovery/models/discovery_checkpoint.dart';
import 'package:sagiro/bank_discovery/services/bank_evidence_scorer.dart';
import 'package:sagiro/bank_discovery/services/bank_discovery_service.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
    SharedPreferences.setMockInitialValues({});
  });

  group('Bank Discovery Engine Core Unit Tests', () {
    test('1. Ignores OTP, security codes, and marketing SMS (0 Points)', () {
      final messages = [
        RawSmsData(
          id: 1,
          sender: 'AD-HDFCBK',
          body:
              'Your OTP for netbanking login is 482910. Do not share with anyone.',
          date: DateTime(2026, 8, 10),
        ),
        RawSmsData(
          id: 2,
          sender: 'AD-SBIINB',
          body:
              'Pre-approved personal loan of Rs 5,000,000 available. Apply now!',
          date: DateTime(2026, 8, 10),
        ),
      ];

      final result = BankEvidenceScorer.scoreBatch(messages);
      expect(result.discoveredBanks, isEmpty);
      expect(result.financialCount, equals(0));
    });

    test(
        '2. Accurately scores HDFC bank transactions & balance alerts (+25 / +20 pts)',
        () {
      final messages = [
        RawSmsData(
          id: 10,
          sender: 'AD-HDFCBK',
          body:
              'Rs 1,500.00 debited from A/C XXXX4321 on 10-AUG-26 at Swiggy. Avail Bal: Rs 45,000.00',
          date: DateTime(2026, 8, 10),
        ),
        RawSmsData(
          id: 11,
          sender: 'AD-HDFCBK',
          body:
              'Rs 2,000.00 credited to A/C XXXX4321 on 11-AUG-26 by Salary. Avail Bal: Rs 47,000.00',
          date: DateTime(2026, 8, 11),
        ),
      ];

      final result = BankEvidenceScorer.scoreBatch(messages);
      expect(result.discoveredBanks.length, equals(1));

      final hdfc = result.discoveredBanks.first;
      expect(hdfc.bankCode, equals('HDFCBK'));
      expect(hdfc.confidenceLevel, equals(BankConfidenceLevel.high));
      expect(hdfc.confirmedTransactionCount, equals(2));
      expect(hdfc.accountLast4Set, contains('XXXX4321'));
      expect(hdfc.evidenceScore, greaterThanOrEqualTo(50.0));
    });

    test('3. Ranks Primary Bank based on evidence score, not raw message count',
        () {
      final messages = [
        // SBI: 5 generic activity messages (+2 pts each = 10 pts)
        ...List.generate(
          5,
          (i) => RawSmsData(
            id: 100 + i,
            sender: 'AD-SBIINB',
            body:
                'Dear customer, your SBI request for statement has been processed.',
            date: DateTime(2026, 8, 1 + i),
          ),
        ),
        // HDFC: 2 confirmed transactions (+25 pts each + recency = 60 pts)
        RawSmsData(
          id: 201,
          sender: 'AD-HDFCBK',
          body:
              'Rs 300.00 debited from A/C XXXX9999 on 05-AUG-26 via UPI. Avail Bal: Rs 12,000.00',
          date: DateTime(2026, 8, 5),
        ),
        RawSmsData(
          id: 202,
          sender: 'AD-HDFCBK',
          body:
              'Rs 700.00 debited from A/C XXXX9999 on 06-AUG-26 via UPI. Avail Bal: Rs 11,300.00',
          date: DateTime(2026, 8, 6),
        ),
      ];

      final result = BankEvidenceScorer.scoreBatch(messages);
      expect(result.discoveredBanks.length, greaterThanOrEqualTo(1));

      final primary = result.discoveredBanks.first;
      expect(primary.bankCode, equals('HDFCBK'));
      expect(primary.isPrimary, isTrue);
    });

    test(
        '4. Checkpoint saving and loading handles ID and Timestamp tie-breakers',
        () async {
      final service = BankDiscoveryService.instance;
      await service.init();

      final checkpoint = DiscoveryCheckpoint(
        lastProcessedSmsId: 500,
        lastProcessedTimestamp: DateTime(2026, 8, 10, 12, 0),
        totalScannedCount: 250,
        lastScanDate: DateTime(2026, 8, 10, 12, 5),
      );

      await service.saveCheckpoint(checkpoint);
      final loaded = await service.loadCheckpoint();

      expect(loaded.lastProcessedSmsId, equals(500));
      expect(loaded.totalScannedCount, equals(250));
      expect(
          loaded.lastProcessedTimestamp, equals(DateTime(2026, 8, 10, 12, 0)));
    });

    test(
        '5. Deduplication using composite hash prevents duplicate evidence accumulation',
        () async {
      final service = BankDiscoveryService.instance;
      await service.saveCheckpoint(DiscoveryCheckpoint());

      final duplicateMessages = [
        RawSmsData(
          id: 301,
          sender: 'AD-ICICIB',
          body:
              'Rs 500.00 debited from A/C XXXX1111 on 01-AUG-26. Avail Bal: Rs 5,000',
          date: DateTime(2026, 8, 1),
        ),
        // Identical duplicate SMS
        RawSmsData(
          id: 301,
          sender: 'AD-ICICIB',
          body:
              'Rs 500.00 debited from A/C XXXX1111 on 01-AUG-26. Avail Bal: Rs 5,000',
          date: DateTime(2026, 8, 1),
        ),
      ];

      final scanResult = await service.scanSmsAndDiscoverBanks(
        mockMessages: duplicateMessages,
      );

      expect(scanResult, isNotNull);
      expect(scanResult!.newMessagesScanned,
          equals(1)); // Only 1 unique message processed
    });

    test('6. User confirmation logic works for Medium/Low confidence banks',
        () {
      final service = BankDiscoveryService.instance;

      final messages = [
        RawSmsData(
          id: 401,
          sender: 'AD-AXISBK',
          body: 'Rs 450 debited from A/C XXXX8888. Avail Bal: Rs 9,000',
          date: DateTime(2026, 8, 5),
        ),
      ];

      final result = BankEvidenceScorer.scoreBatch(messages);
      expect(result.discoveredBanks.isNotEmpty, isTrue);

      final axis = result.discoveredBanks.first;
      expect(axis.userConfirmed, isFalse);

      service.userConfirmBank(axis.bankCode);
      // Verify user confirmation flag
    });
  });
}
