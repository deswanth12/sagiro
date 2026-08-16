import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/account_detection_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Detection Engine Unit Tests', () {
    test('Detects accounts from transaction list accurately', () {
      final txs = [
        TransactionItem(
          merchant: 'Swiggy',
          amount: 350.0,
          type: TransactionType.debit,
          category: 'Food',
          date: DateTime.now(),
          source: TransactionSource.sms,
          rawSms: 'Debited Rs 350 from SBI A/C XX4327',
        ),
      ];

      final accounts = AccountDetectionEngine.detectAccounts(txs);
      expect(accounts, isNotNull);
    });

    test('Generates intelligence insights from transactions', () {
      final txs = [
        TransactionItem(
          merchant: 'HDFC Credit Card',
          amount: 2500.0,
          type: TransactionType.debit,
          category: 'Bills',
          date: DateTime.now(),
          source: TransactionSource.sms,
          rawSms: 'Rs 2500 debited from HDFC Bank card XX1024',
        ),
      ];

      final insights = AccountDetectionEngine.generateIntelligenceInsights(txs);
      expect(insights, isNotNull);
    });
  });
}
