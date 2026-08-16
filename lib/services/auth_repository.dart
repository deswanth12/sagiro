import 'auth_service.dart';
import 'session_manager.dart';

class UserProfileData {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String authMethod; // 'guest' | 'google'
  final DateTime lastLogin;

  UserProfileData({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.authMethod,
    required this.lastLogin,
  });

  bool get isGuest => authMethod == 'guest';
}

/// AuthRepository — Central repository coordinating Firebase Auth and SessionManager.
class AuthRepository {
  final AuthService _authService = AuthService.instance;

  /// Checks existing session state on app boot.
  Future<UserProfileData?> checkActiveSession() async {
    final hasSession = await SessionManager.hasActiveSession();
    if (!hasSession) return null;

    final isGuest = await SessionManager.isGuestMode();
    final details = await SessionManager.getSessionDetails();
    if (isGuest) {
      return UserProfileData(
        uid: details['uid'] ?? 'guest_local_user',
        displayName: details['displayName'] ?? 'Guest User',
        authMethod: 'guest',
        lastLogin:
            DateTime.tryParse(details['lastLogin'] ?? '') ?? DateTime.now(),
      );
    }

    final user = _authService.currentUser;
    if (user != null) {
      await SessionManager.setGoogleSession(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
      return UserProfileData(
        uid: user.uid,
        displayName: user.displayName ?? 'Google User',
        email: user.email,
        photoUrl: user.photoURL,
        authMethod: 'google',
        lastLogin: DateTime.now(),
      );
    }

    // Fallback: Check cached session details if device is offline
    if (details['uid'] != null) {
      return UserProfileData(
        uid: details['uid']!,
        displayName: details['displayName'] ?? 'Google User',
        email: details['email'],
        photoUrl: details['photoUrl'],
        authMethod: 'google',
        lastLogin:
            DateTime.tryParse(details['lastLogin'] ?? '') ?? DateTime.now(),
      );
    }

    return null;
  }

  /// Sign in with Google Account
  Future<UserProfileData?> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    final user = credential?.user;

    if (user == null) {
      return null;
    }

    await SessionManager.setGoogleSession(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );

    return UserProfileData(
      uid: user.uid,
      displayName: user.displayName ?? 'Google User',
      email: user.email,
      photoUrl: user.photoURL,
      authMethod: 'google',
      lastLogin: DateTime.now(),
    );
  }

  /// Sign in as Guest
  Future<UserProfileData> signInAsGuest() async {
    await SessionManager.setGuestSession();
    final details = await SessionManager.getSessionDetails();
    return UserProfileData(
      uid: details['uid'] ?? 'guest_local_user',
      displayName: details['displayName'] ?? 'Guest User',
      authMethod: 'guest',
      lastLogin: DateTime.now(),
    );
  }

  /// Sign Out current session
  Future<void> signOut() async {
    await _authService.signOut();
    await SessionManager.clearSession();
  }
}
