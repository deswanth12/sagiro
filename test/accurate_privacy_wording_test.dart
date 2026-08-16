import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/security_service.dart';

void main() {
  group('Accurate Privacy Wording Regression Tests', () {
    test('Privacy Policy contains exact approved local-first wording', () {
      final privacyPolicyFile = File('lib/views/privacy_policy_page.dart');
      expect(privacyPolicyFile.existsSync(), isTrue);
      final content = privacyPolicyFile.readAsStringSync();

      const expectedWording =
          'Your financial data is processed 100% locally on your device by default. If optional Private Sync is enabled, end-to-end encrypted backups are stored in your personal Google Drive account.';
      expect(content.contains(expectedWording), isTrue);
    });

    test('SecurityService getPrivacyStatus returns Cloud Sync Not Configured',
        () {
      final status = SecurityService.getPrivacyStatus();
      expect(status['dataUploaded'], equals('Cloud Sync Not Configured'));
      expect(status['cloudSync'], equals('Cloud Sync Not Configured'));
    });

    test('No absolute zero bytes or zero cloud claims exist in lib dart files',
        () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final forbiddenPatterns = [
        '0 Bytes',
        'Zero Cloud',
        'Zero Server',
        'Zero Risk',
        'Zero Network'
      ];

      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          expect(
            text.contains(pattern),
            isFalse,
            reason: 'Forbidden pattern found in file',
          );
        }
      }
    });
  });
}
