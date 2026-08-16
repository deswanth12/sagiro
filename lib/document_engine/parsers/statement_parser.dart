import '../models/document_payload.dart';
import '../models/statement_result.dart';
import '../models/parser_capabilities.dart';

abstract class StatementParser {
  String get id;
  String get name;
  String get version;
  ParserCapabilities get capabilities;

  bool supports(DocumentPayload document);
  Future<StatementResult> parse(DocumentPayload document);
}
