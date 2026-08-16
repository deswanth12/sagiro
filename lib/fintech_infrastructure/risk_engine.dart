class LoginRiskEvaluation {
  final int riskScore; // 0 to 100
  final bool requiresMfa;
  final bool isBlocked;
  final String riskReason;

  const LoginRiskEvaluation({
    required this.riskScore,
    required this.requiresMfa,
    required this.isBlocked,
    required this.riskReason,
  });
}

class RiskEngine {
  /// Evaluates login risk based on device fingerprinting, location, and failed attempts
  static LoginRiskEvaluation evaluateLogin({
    required String deviceId,
    required String ipAddress,
    required String country,
    required bool isKnownDevice,
    required int consecutiveFailedAttempts,
  }) {
    int score = 0;
    final reasons = <String>[];

    if (!isKnownDevice) {
      score += 40;
      reasons.add('New unrecognized device');
    }

    if (consecutiveFailedAttempts >= 3) {
      score += 50;
      reasons.add('Multiple failed login attempts');
    }

    if (country != 'India' && country != 'IN') {
      score += 30;
      reasons.add('Unusual geographical location ($country)');
    }

    final isBlocked = score >= 80;
    final requiresMfa = score >= 40;

    return LoginRiskEvaluation(
      riskScore: score.clamp(0, 100),
      requiresMfa: requiresMfa,
      isBlocked: isBlocked,
      riskReason: reasons.isNotEmpty ? reasons.join(' • ') : 'Low risk login',
    );
  }
}
