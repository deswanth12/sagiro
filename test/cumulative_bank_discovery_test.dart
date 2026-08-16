import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/bank_discovery/services/bank_discovery_service.dart';
import 'package:sagiro/bank_discovery/services/bank_evidence_scorer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Cumulative Bank Discovery Tests', () {
    test('Incremental scans accumulate evidence and preserve historical banks',
        () async {
      final service = BankDiscoveryService.instance;
      await service.init();

      final initialMessages = [
        RawSmsData(
          id: 1,
          sender: 'AD-SBIINB',
          body:
              'Rs 500.00 debited from A/c XX1234 on 05-AUG-26. Avail Bal: Rs 15000.00',
          date: DateTime(2026, 8, 5),
        ),
      ];

      final res1 =
          await service.scanSmsAndDiscoverBanks(mockMessages: initialMessages);
      expect(res1, isNotNull);
      expect(res1!.discoveredBanks.length, equals(1));
      expect(res1.discoveredBanks.first.bankCode, equals('SBI'));

      final incrementalMessages = [
        RawSmsData(
          id: 2,
          sender: 'AD-HDFCBK',
          body: 'Rs 1200.00 debited from A/c XX5678. Avail Bal: Rs 22000.00',
          date: DateTime(2026, 8, 6),
        ),
      ];

      final res2 = await service.scanSmsAndDiscoverBanks(
          mockMessages: incrementalMessages);
      expect(res2, isNotNull);
      expect(res2!.discoveredBanks.length, equals(2));

      final bankCodes = res2.discoveredBanks.map((b) => b.bankCode).toList();
      expect(bankCodes, containsAll(['SBI', 'HDFCBK']));

      // Re-initialize service to simulate app restart
      final newService = BankDiscoveryService.instance;
      await newService.init();
      final loadedBanks = await newService.loadDiscoveredBanks();
      expect(loadedBanks.length, equals(2));
    });
  });
}
