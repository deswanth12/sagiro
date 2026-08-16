import '../models/document_payload.dart';
import '../models/statement_result.dart';
import '../models/statement_health.dart';
import '../registry/statement_parser_registry.dart';
import '../duplicate/duplicate_hash_detector.dart';
import '../parsers/pdf/pdf_statement_parser.dart';
import '../parsers/excel/excel_statement_parser.dart';
import '../parsers/csv/csv_statement_parser.dart';
import '../parsers/ocr/ocr_statement_parser.dart';
import '../../models/transaction.dart';

class FinancialDocumentEngine {
  static final FinancialDocumentEngine instance =
      FinancialDocumentEngine._internal();

  FinancialDocumentEngine._internal() {
    _initDefaultParsers();
  }

  void _initDefaultParsers() {
    final registry = StatementParserRegistry.instance;
    registry.registerParser(PdfStatementParser());
    registry.registerParser(ExcelStatementParser());
    registry.registerParser(CsvStatementParser());
    registry.registerParser(OcrStatementParser());
  }

  /// Process Document through the 11-Step Financial Document Engine Pipeline
  Future<StatementResult> processDocument({
    required DocumentPayload document,
    required List<TransactionItem> existingTransactions,
  }) async {
    final registry = StatementParserRegistry.instance;

    // Step 2 & 3: Find registered parser plugin
    final parser = registry.findParser(document);

    if (parser == null) {
      return StatementResult(
        items: [],
        health: const StatementHealth(
          healthScore: 0,
          pageCount: 0,
          totalTransactions: 0,
          openingBalanceVerified: false,
          closingBalanceVerified: false,
          merchantAccuracyPercent: 0,
          duplicatesRemoved: 0,
          parserVersion: 'v0.0.0',
          parseTime: Duration.zero,
        ),
        errorMessage:
            'No matching parser registered for format: ${document.format.name}',
      );
    }

    // Step 4: Extract records via parser
    final rawResult = await parser.parse(document);

    if (rawResult.isPasswordProtected && !rawResult.isDecryptedSuccessfully) {
      return rawResult;
    }

    // Step 8: Perform Cross-Source Duplicate Hash Detection
    final itemsWithDuplicates = <StatementResultItem>[];
    int duplicateCount = 0;

    for (final item in rawResult.items) {
      final isDup = DuplicateHashDetector.isDuplicate(
        candidate: item.transaction,
        existingTransactions: existingTransactions,
      );

      if (isDup) duplicateCount++;

      itemsWithDuplicates.add(StatementResultItem(
        transaction: item.transaction,
        confidence: item.confidence,
        isDuplicate: isDup,
      ));
    }

    final updatedHealth = StatementHealth(
      healthScore: rawResult.health.healthScore,
      pageCount: rawResult.health.pageCount,
      totalTransactions: itemsWithDuplicates.length,
      openingBalanceVerified: rawResult.health.openingBalanceVerified,
      closingBalanceVerified: rawResult.health.closingBalanceVerified,
      merchantAccuracyPercent: rawResult.health.merchantAccuracyPercent,
      duplicatesRemoved: duplicateCount,
      parserVersion: parser.version,
      parseTime: rawResult.health.parseTime,
    );

    return StatementResult(
      items: itemsWithDuplicates,
      health: updatedHealth,
      isPasswordProtected: rawResult.isPasswordProtected,
      isDecryptedSuccessfully: rawResult.isDecryptedSuccessfully,
      warnings: rawResult.warnings,
    );
  }
}
