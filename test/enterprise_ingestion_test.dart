import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/ingestion/extractors/raw_text_extractor.dart';
import 'package:sagiro/ingestion/extractors/table_extractor.dart';
import 'package:sagiro/ingestion/validation/validation_engine.dart';
import 'package:sagiro/ingestion/sessions/import_session.dart';
import 'package:sagiro/ingestion/diagnostics/parser_compatibility_matrix.dart';
import 'package:sagiro/models/transaction.dart';
import 'dart:typed_data';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Enterprise Ingestion & Performance Benchmark Tests', () {
    test('RawTextExtractor extracts text from UTF-8 byte stream', () {
      final bytes = Uint8List.fromList('01/08/2026 SWIGGY ₹450'.codeUnits);
      final text = RawTextExtractor.extractText(bytes);
      expect(text, contains('SWIGGY'));
    });

    test('TableExtractor reconstructs grid rows correctly', () {
      const sampleGrid = '01/08/2026\tZOMATO\t350.00\n02/08/2026\tUBER\t220.00';
      final rows = TableExtractor.extractGrid(sampleGrid);
      expect(rows.length, equals(2));
      expect(rows.first.cells[1], equals('ZOMATO'));
    });

    test(
        'ValidationEngine flags invalid date and zero amounts with skip reasons',
        () {
      final invalidTx = TransactionItem(
        amount: 0.0,
        merchant: 'Unknown',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(1990, 1, 1),
      );

      final res = ValidationEngine.validateTransaction(
        tx: invalidTx,
        existingTransactions: [],
      );

      expect(res.isValid, isFalse);
      expect(res.skipReason, contains('Missing or Zero Amount'));
    });

    test('ImportSession stores immutable session audit record', () {
      final session = ImportSession(
        id: 'sess_1001',
        source: 'PDF Statement',
        parserName: 'SBIParser',
        parserVersion: 'v2.1.0',
        duration: const Duration(milliseconds: 450),
        importedCount: 142,
        duplicateCount: 3,
        skipExplanations: {'Duplicate': 3},
        healthScore: 98,
      );

      expect(session.importedCount, equals(142));
      expect(session.healthScore, equals(98));
      expect(session.duration.inMilliseconds, lessThan(5000));
    });

    test('ParserCompatibilityMatrix generates capability matrix rows', () {
      final matrix = ParserCompatibilityMatrix.getMatrix();
      expect(matrix.length, greaterThanOrEqualTo(6));
      expect(matrix.first.pdf, isTrue);
    });

    test('Performance Benchmark: Processes 10,000 rows within 8-second budget',
        () {
      final Stopwatch stopwatch = Stopwatch()..start();
      final StringBuffer sb = StringBuffer();

      for (int i = 0; i < 10000; i++) {
        sb.writeln('01/08/2026\tMERCHANT_$i\t100.00');
      }

      final rows = TableExtractor.extractGrid(sb.toString());
      stopwatch.stop();

      expect(rows.length, equals(10000));
      expect(stopwatch.elapsedMilliseconds, lessThan(8000));
    });
  });
}
