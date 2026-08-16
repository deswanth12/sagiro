class ParserCapabilities {
  final bool passwordPdf;
  final bool multiPage;
  final bool ocr;
  final bool tables;
  final bool images;
  final bool multiAccount;
  final bool balanceDetection;

  const ParserCapabilities({
    this.passwordPdf = false,
    this.multiPage = true,
    this.ocr = false,
    this.tables = true,
    this.images = false,
    this.multiAccount = true,
    this.balanceDetection = true,
  });

  List<String> get capabilityBadges {
    final badges = <String>[];
    if (passwordPdf) badges.add('🔒 Password PDF');
    if (multiPage) badges.add('📄 Multi-page');
    if (ocr) badges.add('📷 OCR Scan');
    if (tables) badges.add('📊 Table Extraction');
    if (balanceDetection) badges.add('⚖️ Balance Verification');
    return badges;
  }
}
