class FeatureFlagService {
  static bool isPdfParserV2Enabled = true;
  static bool isOcrScannerBetaEnabled = true;
  static bool isParserReplayEnabled = true;

  static Map<String, bool> getAllFlags() => {
        'pdfParserV2': isPdfParserV2Enabled,
        'ocrScannerBeta': isOcrScannerBetaEnabled,
        'parserReplay': isParserReplayEnabled,
      };
}
