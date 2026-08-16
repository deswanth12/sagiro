import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/firebase_options.dart';

void main() {
  group('Firebase Configuration Consistency Tests', () {
    test('firebase_options.dart and google-services.json project IDs match',
        () {
      const androidOptions = DefaultFirebaseOptions.android;
      expect(androidOptions.projectId, equals('paisapilot-98642'));

      final jsonFile = File('android/app/google-services.json');
      expect(jsonFile.existsSync(), isTrue);

      final jsonContent =
          jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
      final projectInfo = jsonContent['project_info'] as Map<String, dynamic>;
      final googleServicesProjectId = projectInfo['project_id'] as String;

      expect(androidOptions.projectId, equals(googleServicesProjectId));
    });
  });
}
