import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/sms_classifier.dart';
import 'package:sagiro/services/sms_parser.dart';

void main() {
  group('Jio and Telecom Recharge SMS Parsing Tests', () {
    test('1. Parses Jio Recharge Successful SMS with Plan Name: 11.0', () {
      const body = '''Recharge Successful !
Plan Name : 11.0
Jio Number : 6303993890
Entitlement :
10GB 4G/5G data thereafter unlimited at 64Kbps. Validity 1 hour
Transaction ID :
178686301089197914971
View plan details -
http://tiny.jio.com/dmyjioplans
You can check usage details for this recharge by clicking
http://tiny.jio.com/dviewstatmnt
Share your recent recharge experience with us -
https://www.jio.com/selfcare/survey/?uid=686353e0-9c75-416f-8e90-712983f1d6e6&lang=en&source=JIO.COM&custid=178686301089197914971''';
      const sender = 'JM-JioPay-S';

      // Step 1: Check classifier
      final classification = SmsClassifier.classify(body, sender);
      expect(classification.isCandidateForParsing, isTrue);

      // Step 2: Check parser
      final result = SmsParser.parseSmsDetailed(body, sender);
      expect(result, isNotNull);
      expect(result!.transaction.amount, 11.0);
      expect(result.transaction.type, TransactionType.debit);
      expect(result.transaction.merchant, 'Jio Recharge');
      expect(result.transaction.account, '6303993890');
      expect(result.transaction.transactionReference, '178686301089197914971');
    });

    test('2. Parses Airtel Recharge Confirmation SMS', () {
      const body =
          'Recharge of Rs 299 is successful for Airtel mobile 9876543210. Txn ID: 412589632.';
      const sender = 'AD-AIRTEL';

      final result = SmsParser.parseSmsDetailed(body, sender);
      expect(result, isNotNull);
      expect(result!.transaction.amount, 299.0);
      expect(result.transaction.type, TransactionType.debit);
      expect(result.transaction.merchant, 'Airtel Recharge');
    });
  });
}
