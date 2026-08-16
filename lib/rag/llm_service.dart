import 'financial_ai_engine.dart';

class LlmService {
  /// Privacy-Preserving On-Device Synthesizer
  /// Guarantees local-first financial processing without third-party telemetry.
  Future<FormattedMoneyBrainResponse> synthesize({
    required String userQuery,
    required FormattedMoneyBrainResponse engineResponse,
  }) async {
    // 100% On-device formatting pass
    return engineResponse;
  }
}
