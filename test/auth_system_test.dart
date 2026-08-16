import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/providers/authentication_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Authentication System Unit Tests', () {
    test('AuthenticationProvider initializes with initial status', () {
      final provider = AuthenticationProvider();
      expect(provider.status, equals(AuthenticationStatus.initial));
      expect(provider.isLoggedIn, isFalse);
    });

    test('Guest mode login sets status to guest', () async {
      final provider = AuthenticationProvider();
      await provider.signInAsGuest();
      expect(provider.status, equals(AuthenticationStatus.guest));
      expect(provider.isLoggedIn, isTrue);
    });
  });
}
