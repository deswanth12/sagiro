class ParserCapabilityRow {
  final String bankOrParser;
  final bool pdf;
  final bool password;
  final bool multiPage;
  final bool tables;
  final bool ocr;
  final bool replay;

  const ParserCapabilityRow({
    required this.bankOrParser,
    required this.pdf,
    required this.password,
    required this.multiPage,
    required this.tables,
    required this.ocr,
    required this.replay,
  });
}

class ParserCompatibilityMatrix {
  static List<ParserCapabilityRow> getMatrix() {
    return const [
      ParserCapabilityRow(
          bankOrParser: 'SBI Bank',
          pdf: true,
          password: true,
          multiPage: true,
          tables: true,
          ocr: false,
          replay: true),
      ParserCapabilityRow(
          bankOrParser: 'HDFC Bank',
          pdf: true,
          password: true,
          multiPage: true,
          tables: true,
          ocr: false,
          replay: true),
      ParserCapabilityRow(
          bankOrParser: 'ICICI Bank',
          pdf: true,
          password: true,
          multiPage: true,
          tables: true,
          ocr: false,
          replay: true),
      ParserCapabilityRow(
          bankOrParser: 'Axis Bank',
          pdf: true,
          password: true,
          multiPage: true,
          tables: true,
          ocr: false,
          replay: true),
      ParserCapabilityRow(
          bankOrParser: 'Universal Excel',
          pdf: false,
          password: false,
          multiPage: true,
          tables: true,
          ocr: false,
          replay: true),
      ParserCapabilityRow(
          bankOrParser: 'Paper OCR Scanner',
          pdf: false,
          password: false,
          multiPage: false,
          tables: true,
          ocr: true,
          replay: false),
    ];
  }
}
