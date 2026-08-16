import '../models/document_payload.dart';
import '../pipeline/financial_document_engine.dart';
import '../../models/transaction.dart';

class ParserReplayResult {
  final int reprocessedCount;
  final int upgradedCount;
  final String parserVersion;

  const ParserReplayResult({
    required this.reprocessedCount,
    required this.upgradedCount,
    required this.parserVersion,
  });
}

class ParserReplayEngine {
  static Future<ParserReplayResult> replayStatements({
    required List<DocumentPayload> historicalStatements,
    required List<TransactionItem> currentTransactions,
  }) async {
    int reprocessed = 0;
    int upgraded = 0;

    for (final stmt in historicalStatements) {
      final res = await FinancialDocumentEngine.instance.processDocument(
        document: stmt,
        existingTransactions: currentTransactions,
      );

      reprocessed += res.items.length;
      upgraded += res.readyCount;
    }

    return ParserReplayResult(
      reprocessedCount: reprocessed,
      upgradedCount: upgraded,
      parserVersion: 'v2.1.0',
    );
  }
}
