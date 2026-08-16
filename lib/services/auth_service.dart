import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService — Manages Firebase Google Sign-In Authentication.
class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static const String webClientId =
      '657194860112-a6v065qbhvjdm5uj8nh6inmnhd4ldn41.apps.googleusercontent.com';

  User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('[Auth] currentUser fallback: $e');
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      debugPrint('[Auth] authStateChanges fallback: $e');
      return Stream.value(null);
    }
  }

  /// Initiates Google Sign-In flow with Firebase Web Client ID.
  Future<UserCredential?> signInWithGoogle() async {
    debugPrint('[Auth] Google Sign-In flow started');
    try {
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId: webClientId,
              scopes: ['email', 'profile'],
            )
          : GoogleSignIn(
              serverClientId: webClientId,
              scopes: ['email', 'profile'],
            );

      debugPrint('[Auth] Credential request started');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[Auth] Google Sign-In was cancelled by user');
        return null; // User canceled sign-in
      }

      debugPrint('[Auth] Account selected, retrieving authentication tokens');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        debugPrint('[Auth] Failed: both accessToken and idToken are null');
        throw Exception('Failed to obtain Google authentication tokens.');
      }

      debugPrint('[Auth] Credential received');
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('[Auth] Firebase authentication started');
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint(
          '[Auth] Firebase authentication success: uid=${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      debugPrint('[Auth] Firebase authentication failure: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup_closed') ||
          errStr.contains('cancelled') ||
          errStr.contains('canceled')) {
        return null; // Return null gracefully when sign-in prompt is dismissed
      }
      rethrow;
    }
  }

  /// Signs out user from both Firebase Auth & Google Sign-In.
  Future<void> signOut() async {
    debugPrint('[Auth] Sign-out started');
    try {
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId: webClientId,
            )
          : GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('[Auth] googleSignOut fallback: $e');
    }
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('[Auth] Sign-out success');
    } catch (e) {
      debugPrint('[Auth] firebaseSignOut fallback: $e');
    }
  }
}
