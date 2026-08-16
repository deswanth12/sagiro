import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/account_engine/models/account_model.dart';
import 'package:sagiro/account_engine/models/account_type.dart';
import 'package:sagiro/account_engine/services/account_matching_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Engine Unit Tests', () {
    test('AccountMatchResult serializes and holds values cleanly', () {
      final res = AccountMatchResult(
        confidenceScore: 0.95,
        candidateBank: 'SBI',
        candidateLast4: '4327',
        candidateCategory: AccountCategory.savings,
        reason: 'Exact last4 match',
      );

      expect(res.confidenceScore, equals(0.95));
      expect(res.candidateBank, equals('SBI'));
      expect(res.candidateLast4, equals('4327'));
      expect(res.candidateCategory, equals(AccountCategory.savings));
    });

    test('AccountModel instantiates with correct defaults', () {
      final acc = AccountModel(
        id: 'acc_sbi_1',
        bankName: 'SBI',
        maskedAccountNumber: '4327',
        nickname: 'SBI Savings',
        accountType: AccountCategory.savings,
        estimatedBalance: 15000.0,
        lastKnownBalance: 15000.0,
        iconEmoji: '🏦',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(acc.id, equals('acc_sbi_1'));
      expect(acc.bankName, equals('SBI'));
      expect(acc.estimatedBalance, equals(15000.0));
    });
  });
}
