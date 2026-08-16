import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagiro/services/money_guide_quota_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('MoneyGuideQuotaService Token Quota Unit Tests', () {
    test('Free users start with 50 remaining tokens', () async {
      final remaining = await MoneyGuideQuotaService.getRemainingTokens(false);
      final used = await MoneyGuideQuotaService.getUsedTokens();
      final canConsume = await MoneyGuideQuotaService.canConsumeToken(false);

      expect(remaining, equals(50));
      expect(used, equals(0));
      expect(canConsume, isTrue);
    });

    test('Pro users have unlimited tokens (-1 remaining)', () async {
      final remaining = await MoneyGuideQuotaService.getRemainingTokens(true);
      final canConsume = await MoneyGuideQuotaService.canConsumeToken(true);

      expect(remaining, equals(-1));
      expect(canConsume, isTrue);
    });

    test('Free users consume tokens 1 by 1', () async {
      var remaining = await MoneyGuideQuotaService.consumeToken(false);
      expect(remaining, equals(49));

      remaining = await MoneyGuideQuotaService.consumeToken(false);
      expect(remaining, equals(48));

      final used = await MoneyGuideQuotaService.getUsedTokens();
      expect(used, equals(2));
    });

    test('Free user cannot consume tokens once limit of 50 is reached',
        () async {
      // Simulate consuming 50 tokens
      for (int i = 0; i < 50; i++) {
        await MoneyGuideQuotaService.consumeToken(false);
      }

      final remaining = await MoneyGuideQuotaService.getRemainingTokens(false);
      final canConsume = await MoneyGuideQuotaService.canConsumeToken(false);

      expect(remaining, equals(0));
      expect(canConsume, isFalse);
    });

    test('Pro users consuming tokens does not decrement quota', () async {
      final remaining = await MoneyGuideQuotaService.consumeToken(true);
      expect(remaining, equals(-1));

      final used = await MoneyGuideQuotaService.getUsedTokens();
      expect(used, equals(0));
    });
  });
}
