import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/voice_expense_service.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Voice Expense Entry Service Unit Tests', () {
    test('Parses food expense transcript correctly', () {
      final res =
          VoiceExpenseService.parseVoiceTranscript('Spent 450 on Swiggy lunch');
      expect(res.amount, equals(450.0));
      expect(res.category, equals('Food & Dining'));
      expect(res.merchant, equals('Swiggy'));
      expect(res.type, equals(TransactionType.debit));
      expect(res.confidenceScore, greaterThan(0.9));
    });

    test('Parses groceries transcript correctly', () {
      final res = VoiceExpenseService.parseVoiceTranscript(
          'Paid Rs 1200 for groceries at Blinkit');
      expect(res.amount, equals(1200.0));
      expect(res.category, equals('Groceries'));
      expect(res.merchant, equals('Blinkit'));
      expect(res.type, equals(TransactionType.debit));
    });

    test('Parses transportation transcript correctly', () {
      final res =
          VoiceExpenseService.parseVoiceTranscript('Uber cab fare 320 rupees');
      expect(res.amount, equals(320.0));
      expect(res.category, equals('Transportation'));
      expect(res.merchant, equals('Uber'));
      expect(res.type, equals(TransactionType.debit));
    });

    test('Parses income salary transcript correctly', () {
      final res =
          VoiceExpenseService.parseVoiceTranscript('Received 25000 salary');
      expect(res.amount, equals(25000.0));
      expect(res.category, equals('Income'));
      expect(res.type, equals(TransactionType.credit));
      expect(res.categoryEmoji, equals('💰'));
    });

    test('Parses cashback reward transcript correctly', () {
      final res = VoiceExpenseService.parseVoiceTranscript('Got 500 cashback');
      expect(res.amount, equals(500.0));
      expect(res.type, equals(TransactionType.credit));
    });

    test('Handles empty transcript safely', () {
      final res = VoiceExpenseService.parseVoiceTranscript('');
      expect(res.amount, equals(0.0));
      expect(res.confidenceScore, equals(0.0));
    });
  });
}
