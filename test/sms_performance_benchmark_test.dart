import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/sms_parser.dart';

void main() {
  group('SMS Scanner Performance Benchmark & Accuracy Suite', () {
    test('Measures processing times across 0, 100, 500, 1000, 2000 SMS batches',
        () {
      final batchSizes = [0, 100, 500, 1000, 2000];

      for (final size in batchSizes) {
        final messages = _generateSmsBatch(size, mixedRatio: 0.5);
        final sw = Stopwatch()..start();

        int parsedCount = 0;
        for (final sms in messages) {
          final res = SmsParser.parseSmsDetailed(sms['body']!, sms['sender']!);
          if (res != null) parsedCount++;
        }
        sw.stop();

        // Print benchmark metrics to console output
        // ignore: avoid_print
        print(
            '[BENCHMARK] $size SMS processed in ${sw.elapsedMilliseconds} ms (${sw.elapsedMicroseconds / (size == 0 ? 1 : size)} µs/SMS). Parsed: $parsedCount');

        // Assert speed requirement (< 2 ms per SMS + baseline)
        if (size > 0) {
          expect(sw.elapsedMilliseconds, lessThan(size * 2 + 150));
        }
      }
    });

    test(
        'Measures performance on 2,000 mostly irrelevant SMS vs mostly bank SMS',
        () {
      final irrelevant =
          _generateSmsBatch(2000, mixedRatio: 0.0); // 100% irrelevant/OTP/promo
      final bankOnly =
          _generateSmsBatch(2000, mixedRatio: 1.0); // 100% bank SMS

      final swIrrelevant = Stopwatch()..start();
      for (final sms in irrelevant) {
        SmsParser.parseSmsDetailed(sms['body']!, sms['sender']!);
      }
      swIrrelevant.stop();

      final swBank = Stopwatch()..start();
      for (final sms in bankOnly) {
        SmsParser.parseSmsDetailed(sms['body']!, sms['sender']!);
      }
      swBank.stop();

      // ignore: avoid_print
      print(
          '[BENCHMARK] 2,000 Irrelevant SMS: ${swIrrelevant.elapsedMilliseconds} ms');
      // ignore: avoid_print
      print(
          '[BENCHMARK] 2,000 Bank-Only SMS: ${swBank.elapsedMilliseconds} ms');

      // Irrelevant SMS should be rejected instantly via fast early exit
      expect(swIrrelevant.elapsedMilliseconds, lessThan(200));
    });

    test('Verifies duplicate detection accuracy and reference extraction', () {
      const rawSms =
          'Txn of Rs. 1500.00 debited from A/C XX4321 at SWIGGY on 13-08-2026. Ref/UTR: UPI123456789.';
      final res1 = SmsParser.parseSmsDetailed(rawSms, 'AX-HDFCBK');
      final res2 = SmsParser.parseSmsDetailed(rawSms, 'AX-HDFCBK');

      expect(res1, isNotNull);
      expect(res2, isNotNull);
      expect(res1!.transaction.transactionReference, equals('UPI123456789'));
      expect(res2!.transaction.transactionReference, equals('UPI123456789'));
      expect(res1.transaction.rawSms, isNull); // Privacy verification
    });
  });
}

List<Map<String, String>> _generateSmsBatch(int count,
    {double mixedRatio = 0.5}) {
  final list = <Map<String, String>>[];
  for (int i = 0; i < count; i++) {
    if (i < (count * mixedRatio)) {
      list.add({
        'sender': 'AX-HDFCBK',
        'body':
            'Rs. ${(i % 500) + 10}.00 debited from A/C XX1234 on 13-08-2026 at Swiggy. Ref: UTR$i.',
      });
    } else {
      list.add({
        'sender': 'AD-PROMO',
        'body':
            'Your OTP for logging in is ${100000 + i}. Do not share this OTP with anyone.',
      });
    }
  }
  return list;
}
