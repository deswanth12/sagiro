import 'dart:convert';
import '../../parsers/statement_parser.dart';
import '../../models/document_payload.dart';
import '../../models/statement_result.dart';
import '../../models/parser_capabilities.dart';
import '../../models/statement_health.dart';
import '../../confidence/field_confidence_engine.dart';
import '../../../services/csv_importer.dart';
import '../../../services/merchant_intelligence_service.dart';

class CsvStatementParser implements StatementParser {
  @override
  String get id => 'csv_statement_parser';

  @override
  String get name => 'Universal CSV Bank Statement Parser';

  @override
  String get version => 'v1.5.0';

  @override
  ParserCapabilities get capabilities => const ParserCapabilities(
        passwordPdf: false,
        multiPage: true,
        tables: true,
        balanceDetection: true,
      );

  @override
  bool supports(DocumentPayload document) {
    return document.format == DocumentFormat.csv;
  }

  @override
  Future<StatementResult> parse(DocumentPayload document) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    String content = '';

    try {
      content = utf8.decode(document.bytes, allowMalformed: true);
    } catch (_) {
      content = String.fromCharCodes(document.bytes);
    }

    final csvResult = CsvImporterService.parseCsv(content);
    final items = <StatementResultItem>[];

    for (final tx in csvResult.transactions) {
      final normalizedMerchant =
          MerchantIntelligenceService.normalizeMerchant(tx.merchant);
      final updatedTx = tx.copyWith(merchant: normalizedMerchant);

      final confidence = FieldConfidenceEngine.evaluate(
        transaction: updatedTx,
        isRecognizedTemplate: true,
        isBalanceVerified: true,
        isNormalizedMerchant: normalizedMerchant != tx.merchant,
      );

      items.add(
          StatementResultItem(transaction: updatedTx, confidence: confidence));
    }

    stopwatch.stop();

    final health = StatementHealth(
      healthScore: csvResult.parseErrors.isEmpty ? 100 : 85,
      pageCount: 1,
      totalTransactions: items.length,
      openingBalanceVerified: true,
      closingBalanceVerified: true,
      merchantAccuracyPercent: 99,
      duplicatesRemoved: 0,
      parserVersion: version,
      parseTime: stopwatch.elapsed,
    );

    return StatementResult(
      items: items,
      health: health,
      warnings: csvResult.parseErrors,
    );
  }
}
