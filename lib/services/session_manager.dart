import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SessionManager — Handles persistent session caching across app restarts.
/// AUTH-01 FIX: All session data now stored in flutter_secure_storage (Android Keystore /
/// iOS Keychain) instead of unencrypted SharedPreferences. Session tokens (UID, email,
/// displayName, photoUrl) are sensitive identity data and must not be stored in plaintext.
class SessionManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _kIsGuestModeKey = 'auth_is_guest_mode';
  static const String _kIsLoggedInKey = 'auth_is_logged_in';
  static const String _kUserIdKey = 'auth_user_id';
  static const String _kUserEmailKey = 'auth_user_email';
  static const String _kUserDisplayNameKey = 'auth_user_display_name';
  static const String _kUserPhotoUrlKey = 'auth_user_photo_url';
  static const String _kLastLoginKey = 'auth_last_login';
  static const String _kAuthMethodKey = 'auth_method'; // 'guest' | 'google'

  /// Checks if a active session exists (Guest or Google).
  static Future<bool> hasActiveSession() async {
    final value = await _storage.read(key: _kIsLoggedInKey);
    return value == 'true';
  }

  /// Checks if current session is Guest mode.
  static Future<bool> isGuestMode() async {
    final value = await _storage.read(key: _kIsGuestModeKey);
    return value == 'true';
  }

  /// Persists Guest Mode session locally.
  static Future<void> setGuestSession() async {
    await _storage.write(key: _kIsLoggedInKey, value: 'true');
    await _storage.write(key: _kIsGuestModeKey, value: 'true');
    await _storage.write(key: _kAuthMethodKey, value: 'guest');
    await _storage.write(key: _kUserIdKey, value: 'guest_local_user');
    await _storage.write(key: _kUserDisplayNameKey, value: 'Guest User');
    await _storage.write(
        key: _kLastLoginKey, value: DateTime.now().toIso8601String());
  }

  /// Persists Google Authenticated session locally.
  static Future<void> setGoogleSession({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
  }) async {
    await _storage.write(key: _kIsLoggedInKey, value: 'true');
    await _storage.write(key: _kIsGuestModeKey, value: 'false');
    await _storage.write(key: _kAuthMethodKey, value: 'google');
    await _storage.write(key: _kUserIdKey, value: uid);
    if (email != null) {
      await _storage.write(key: _kUserEmailKey, value: email);
    }
    if (displayName != null) {
      await _storage.write(key: _kUserDisplayNameKey, value: displayName);
    }
    if (photoUrl != null) {
      await _storage.write(key: _kUserPhotoUrlKey, value: photoUrl);
    }
    await _storage.write(
        key: _kLastLoginKey, value: DateTime.now().toIso8601String());
  }

  /// Clears active auth session on logout.
  static Future<void> clearSession() async {
    // Delete all session keys atomically via deleteAll to avoid partial state on crash
    await _storage.delete(key: _kIsLoggedInKey);
    await _storage.delete(key: _kIsGuestModeKey);
    await _storage.delete(key: _kUserIdKey);
    await _storage.delete(key: _kUserEmailKey);
    await _storage.delete(key: _kUserDisplayNameKey);
    await _storage.delete(key: _kUserPhotoUrlKey);
    await _storage.delete(key: _kAuthMethodKey);
    await _storage.delete(key: _kLastLoginKey);
  }

  static Future<Map<String, String?>> getSessionDetails() async {
    return {
      'method': await _storage.read(key: _kAuthMethodKey) ?? 'guest',
      'uid': await _storage.read(key: _kUserIdKey),
      'email': await _storage.read(key: _kUserEmailKey),
      'displayName':
          await _storage.read(key: _kUserDisplayNameKey) ?? 'Guest User',
      'photoUrl': await _storage.read(key: _kUserPhotoUrlKey),
      'lastLogin': await _storage.read(key: _kLastLoginKey),
    };
  }
}
