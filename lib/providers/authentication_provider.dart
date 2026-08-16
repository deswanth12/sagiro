import 'package:flutter/foundation.dart';
import '../services/auth_repository.dart';

enum AuthenticationStatus {
  initial,
  loading,
  authenticated,
  guest,
  error,
}

class AuthenticationProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AuthenticationStatus _status = AuthenticationStatus.initial;
  AuthenticationStatus get status => _status;

  UserProfileData? _userProfile;
  UserProfileData? get userProfile => _userProfile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn =>
      _status == AuthenticationStatus.authenticated ||
      _status == AuthenticationStatus.guest;
  bool get isGuest => _status == AuthenticationStatus.guest;
  bool get isGoogleUser => _status == AuthenticationStatus.authenticated;

  Future<void> checkAuthStatus() async {
    _status = AuthenticationStatus.loading;
    notifyListeners();

    try {
      final profile = await _repository.checkActiveSession();
      if (profile != null) {
        _userProfile = profile;
        _status = profile.isGuest
            ? AuthenticationStatus.guest
            : AuthenticationStatus.authenticated;
      } else {
        _status = AuthenticationStatus.initial;
      }
    } catch (e) {
      debugPrint('AuthenticationProvider.checkAuthStatus error: $e');
      _status = AuthenticationStatus.initial;
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    debugPrint('[Auth] Google Sign-In button clicked');
    _status = AuthenticationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _repository.signInWithGoogle();
      if (profile == null) {
        // User cancelled or dismissed sign-in prompt — reset state cleanly
        debugPrint('[Auth] Sign-in cancelled by user');
        _status = AuthenticationStatus.initial;
        _errorMessage = null;
        notifyListeners();
        return false;
      }

      _userProfile = profile;
      _status = AuthenticationStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthenticationStatus.error;
      final errLower = e.toString().toLowerCase();
      if (errLower.contains('cancelled') ||
          errLower.contains('canceled') ||
          errLower.contains('popup_closed')) {
        _status = AuthenticationStatus.initial;
        _errorMessage = null;
      } else if (errLower.contains('network') ||
          errLower.contains('socketexception') ||
          errLower.contains('connection') ||
          errLower.contains('offline')) {
        _errorMessage =
            'Unable to connect to Google services. Please check your internet connection and try again.';
      } else {
        final cleanError = e.toString()
            .replaceAll('PlatformException(', '')
            .replaceAll('Exception:', '')
            .replaceAll(')', '')
            .trim();
        _errorMessage = 'Google Sign-In failed: $cleanError';
      }
      debugPrint('[Auth] Sign-in error: $_errorMessage (Details: $e)');
      notifyListeners();
      return false;
    }
  }

  Future<void> signInAsGuest() async {
    _status = AuthenticationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _repository.signInAsGuest();
      _status = AuthenticationStatus.guest;
    } catch (e) {
      _status = AuthenticationStatus.error;
      _errorMessage = 'Failed to start Guest session';
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _status = AuthenticationStatus.loading;
    notifyListeners();

    try {
      await _repository.signOut();
    } catch (e) {
      debugPrint('AuthenticationProvider.signOut error: $e');
    }

    _userProfile = null;
    _status = AuthenticationStatus.initial;
    notifyListeners();
  }
}
