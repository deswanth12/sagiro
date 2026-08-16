import 'dart:math';

class TotpMfaService {
  /// Flag indicating server-side TOTP MFA integration status.
  /// Currently false — TOTP verification is not offered in production UI until server auth is live.
  static const bool isLive = false;

  /// Generates cryptographically random 24-character backup recovery codes
  static List<String> generateBackupRecoveryCodes() {
    final random = Random.secure();
    return List.generate(4, (_) {
      final a = random.nextInt(9000) + 1000;
      final b = random.nextInt(9000) + 1000;
      return 'REC-$a-$b';
    });
  }

  /// Verifies a 6-digit TOTP code against the server.
  /// Unintegrated stub — returns false when not live.
  static bool verifyTotpCode(String code) {
    if (!isLive) return false;
    if (code.length != 6) return false;
    return false;
  }
}
