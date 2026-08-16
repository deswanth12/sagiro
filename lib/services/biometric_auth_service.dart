import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'app_settings_service.dart';

class BiometricAuthService {
  static final BiometricAuthService instance = BiometricAuthService._();
  BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if hardware supports biometrics / device auth
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (e) {
      debugPrint('BiometricAuthService isBiometricsAvailable error: $e');
      return false;
    }
  }

  /// Perform biometric/passcode authentication prompt
  Future<bool> authenticate(
      {String reason = 'Authenticate to access Sagiro'}) async {
    if (kIsWeb) return true;
    try {
      final available = await isBiometricsAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService authenticate PlatformException: $e');
      return false;
    } catch (e) {
      debugPrint('BiometricAuthService authenticate error: $e');
      return false;
    }
  }

  /// Request verification before enabling biometric lock setting
  Future<bool> enableBiometricsWithVerification() async {
    if (kIsWeb) {
      await AppSettingsService.instance.setBiometricsEnabled(true);
      return true;
    }

    try {
      final authenticated = await authenticate(
        reason: 'Verify your fingerprint or screen lock to enable App Lock',
      );

      if (authenticated) {
        await AppSettingsService.instance.setBiometricsEnabled(true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('enableBiometricsWithVerification error: $e');
      return false;
    }
  }
}
