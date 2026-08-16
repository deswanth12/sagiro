import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/document_engine/models/document_payload.dart';
import 'package:sagiro/document_engine/pipeline/financial_document_engine.dart';
import 'package:sagiro/document_engine/registry/statement_parser_registry.dart';
import 'package:sagiro/document_engine/duplicate/duplicate_hash_detector.dart';
import 'package:sagiro/document_engine/replay/parser_replay_engine.dart';
import 'package:sagiro/models/transaction.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('FinancialDocumentEngine Unit & Integration Tests', () {
    test('StatementParserRegistry loads default parsers cleanly', () {
      final registry = StatementParserRegistry.instance;
      expect(registry.registeredParsers.length, greaterThanOrEqualTo(4));
    });

    test('Parses Text PDF statement correctly with high health score',
        () async {
      const samplePdfContent = '''
%PDF-1.4
01/08/2026 SWIGGY UPI Rs. 450.00 Debit
02/08/2026 AMAZON PAY Rs 1,200.00 Debit
''';

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(samplePdfContent.codeUnits),
        fileName: 'HDFC_Statement.pdf',
        format: DocumentFormat.pdf,
      );

      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(result.items.length, equals(2));
      expect(result.health.isHealthy, isTrue);
      expect(result.items.first.transaction.merchant, equals('Swiggy'));
    });

    test('Detects Password-Protected PDF statement without throwing exceptions',
        () async {
      const encryptedHeader = '%PDF-1.4 /Encrypt 12 0 R /Filter /Standard';
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(encryptedHeader.codeUnits),
        fileName: 'SBI_Protected.pdf',
        format: DocumentFormat.pdf,
      );

      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(result.isPasswordProtected, isTrue);
      expect(result.isDecryptedSuccessfully, isFalse);
      expect(result.errorMessage, contains('password protected'));
    });

    test('Parses Excel (.xlsx/.xls) statement ignoring totals and headers',
        () async {
      const excelText = '''
Date\tDescription\tAmount
01/08/2026\tZOMATO\t₹350.00
Opening Balance\tSummary\t₹50,000
Total\tSummary\t₹350.00
''';

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(excelText)),
        fileName: 'Expenses.xlsx',
        format: DocumentFormat.excel,
      );

      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(result.items.length, equals(1));
      expect(result.items.first.transaction.merchant, equals('Zomato'));
    });

    test('Parses Camera Paper Scan (OCR) statement on-device', () async {
      const ocrText = '03/08/2026 UBER TRIP Rs 240.00 Debit';
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(ocrText.codeUnits),
        fileName: 'CameraScan.jpg',
        format: DocumentFormat.ocrImage,
      );

      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(result.items.length, equals(1));
      expect(result.items.first.transaction.merchant, equals('Uber'));
    });

    test('DuplicateHashDetector prevents duplicate records across sources', () {
      final tx1 = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 1),
      );

      final tx2 = TransactionItem(
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime(2026, 8, 1),
      );

      final isDup = DuplicateHashDetector.isDuplicate(
        candidate: tx2,
        existingTransactions: [tx1],
      );

      expect(isDup, isTrue);
    });

    test('ParserReplayEngine reprocesses historical statements safely',
        () async {
      const text = '05/08/2026 FLIPKART Rs 1,499.00 Debit';
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(text.codeUnits),
        fileName: 'Statement.pdf',
        format: DocumentFormat.pdf,
      );

      final replayRes = await ParserReplayEngine.replayStatements(
        historicalStatements: [payload],
        currentTransactions: [],
      );

      expect(replayRes.reprocessedCount, equals(1));
      expect(replayRes.upgradedCount, equals(1));
    });
  });
}
