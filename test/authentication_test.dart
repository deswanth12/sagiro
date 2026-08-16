import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagiro/services/session_manager.dart';
import 'package:sagiro/providers/authentication_provider.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();

    // Mock flutter_secure_storage platform channel so unit tests can run
    // without an Android Keystore / iOS Keychain. Uses an in-memory map.
    final Map<String, String> secureStore = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'write':
            final key = methodCall.arguments['key'] as String;
            final value = methodCall.arguments['value'] as String?;
            if (value != null) secureStore[key] = value;
            return null;
          case 'read':
            final key = methodCall.arguments['key'] as String;
            return secureStore[key];
          case 'delete':
            final key = methodCall.arguments['key'] as String;
            secureStore.remove(key);
            return null;
          case 'deleteAll':
            secureStore.clear();
            return null;
          case 'readAll':
            return Map<String, String>.from(secureStore);
          case 'containsKey':
            final key = methodCall.arguments['key'] as String;
            return secureStore.containsKey(key);
          default:
            return null;
        }
      },
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionManager Tests', () {
    test('Defaults to no active session', () async {
      final hasSession = await SessionManager.hasActiveSession();
      final isGuest = await SessionManager.isGuestMode();

      expect(hasSession, isFalse);
      expect(isGuest, isFalse);
    });

    test('Persists Guest session correctly', () async {
      await SessionManager.setGuestSession();

      final hasSession = await SessionManager.hasActiveSession();
      final isGuest = await SessionManager.isGuestMode();
      final details = await SessionManager.getSessionDetails();

      expect(hasSession, isTrue);
      expect(isGuest, isTrue);
      expect(details['displayName'], equals('Guest User'));
      expect(details['method'], equals('guest'));
    });

    test('Persists Google session correctly', () async {
      await SessionManager.setGoogleSession(
        uid: 'user_12345',
        email: 'test@example.com',
        displayName: 'Test Pilot',
        photoUrl: 'https://example.com/photo.jpg',
      );

      final hasSession = await SessionManager.hasActiveSession();
      final isGuest = await SessionManager.isGuestMode();
      final details = await SessionManager.getSessionDetails();

      expect(hasSession, isTrue);
      expect(isGuest, isFalse);
      expect(details['uid'], equals('user_12345'));
      expect(details['email'], equals('test@example.com'));
      expect(details['displayName'], equals('Test Pilot'));
    });

    test('Clears session on logout', () async {
      await SessionManager.setGuestSession();
      await SessionManager.clearSession();

      final hasSession = await SessionManager.hasActiveSession();
      expect(hasSession, isFalse);
    });
  });

  group('AuthenticationProvider Tests', () {
    test('signInAsGuest updates provider status to guest', () async {
      final provider = AuthenticationProvider();
      expect(provider.status, equals(AuthenticationStatus.initial));

      await provider.signInAsGuest();

      expect(provider.status, equals(AuthenticationStatus.guest));
      expect(provider.isGuest, isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.userProfile?.displayName, equals('Guest User'));
    });

    test('signOut resets provider status to initial', () async {
      final provider = AuthenticationProvider();
      await provider.signInAsGuest();

      await provider.signOut();

      expect(provider.status, equals(AuthenticationStatus.initial));
      expect(provider.isLoggedIn, isFalse);
      expect(provider.userProfile, isNull);
    });
  });
}
