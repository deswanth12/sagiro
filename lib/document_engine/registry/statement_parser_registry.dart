import '../parsers/statement_parser.dart';
import '../models/document_payload.dart';
import 'bank_template.dart';
import '../parsers/pdf/pdf_statement_parser.dart';
import '../parsers/excel/excel_statement_parser.dart';
import '../parsers/csv/csv_statement_parser.dart';
import '../parsers/ocr/ocr_statement_parser.dart';

class StatementParserRegistry {
  static final StatementParserRegistry instance =
      StatementParserRegistry._internal();

  final List<StatementParser> _parsers = [];
  final List<BankTemplate> _templates = [];

  StatementParserRegistry._internal() {
    _registerDefaults();
  }

  void _registerDefaults() {
    registerParser(PdfStatementParser());
    registerParser(ExcelStatementParser());
    registerParser(CsvStatementParser());
    registerParser(OcrStatementParser());
  }

  /// Register a parser plugin
  void registerParser(StatementParser parser) {
    _parsers.removeWhere((p) => p.id == parser.id);
    _parsers.add(parser);
  }

  /// Register a declarative bank template
  void registerTemplate(BankTemplate template) {
    _templates.removeWhere((t) => t.bankId == template.bankId);
    _templates.add(template);
  }

  /// Find matching parser for document payload
  StatementParser? findParser(DocumentPayload document) {
    if (_parsers.isEmpty) _registerDefaults();
    for (final parser in _parsers) {
      if (parser.supports(document)) return parser;
    }
    return null;
  }

  List<StatementParser> get registeredParsers => List.unmodifiable(_parsers);
  List<BankTemplate> get registeredTemplates => List.unmodifiable(_templates);
}
