import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/sms_parser.dart';

void main() {
  group('Privacy SMS Retention Tests', () {
    test('Parsed transaction does not store full raw SMS body', () {
      const rawBody =
          'Rs 450.00 debited from A/c XX1234 on 05-AUG-26 at Swiggy. Ref: 607712345678. Avail Bal: Rs 12000.00';
      final res = SmsParser.parseSmsDetailed(rawBody, 'AD-SBIINB');

      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(450.0));
      expect(res.transaction.merchant, equals('Swiggy'));
      expect(res.transaction.account, equals('XX1234'));
      expect(res.transaction.rawSms, isNull);
    });

    test('TransactionItem toMap always nullifies rawSms for DB persistence',
        () {
      final tx = TransactionItem(
        amount: 250.0,
        merchant: 'Uber',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
        rawSms: 'Sensitive raw SMS body string',
      );

      final map = tx.toMap();
      expect(map['rawSms'], isNull);
    });
  });
}
