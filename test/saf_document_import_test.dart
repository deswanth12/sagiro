import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/saf_document_reader.dart';
import 'package:sagiro/document_engine/models/document_payload.dart';
import 'package:sagiro/document_engine/pipeline/financial_document_engine.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('SAF Document Import Architecture Unit Tests', () {
    test(
        '1. PDF selection: detectFormat and processDocument handle document payload',
        () async {
      final pdfFormat =
          DocumentPayload.detectFormat('SBI_Statement (Jan 2026) #1.pdf');
      expect(pdfFormat, equals(DocumentFormat.pdf));

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(
            'Date,Description,Amount,Type\n2026-08-01,Swiggy Order,250.00,DEBIT\n')),
        fileName: 'SBI_Statement (Jan 2026) #1.csv',
        format: DocumentFormat.csv,
      );

      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(result.items.isNotEmpty, isTrue);
      expect(result.items.first.transaction.merchant, contains('Swiggy'));
    });

    test('2. CSV selection: detects Unicode filename and parses records',
        () async {
      const fileName = 'सपना_kharcha (1).csv';
      final format = DocumentPayload.detectFormat(fileName);
      expect(format, equals(DocumentFormat.csv));

      const csvContent =
          'Date,Description,Amount,Type\n2026-08-05,D-Mart Groceries,1450.00,DEBIT\n2026-08-06,Salary Credit,75000.00,CREDIT\n';
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(csvContent)),
        fileName: fileName,
        format: format,
      );

      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(result.items.length, equals(2));
      expect(result.items.first.transaction.amount, equals(1450.00));
    });

    test('3. XLS/XLSX selection: detects Excel format correctly', () {
      final xlsFormat = DocumentPayload.detectFormat('Khata 2026-08.xls');
      final xlsxFormat = DocumentPayload.detectFormat('HDFC_Export_2026.xlsx');

      expect(xlsFormat, equals(DocumentFormat.excel));
      expect(xlsxFormat, equals(DocumentFormat.excel));
    });

    test('4. Image selection: detects JPG/PNG/HEIC format for OCR pipeline',
        () {
      expect(DocumentPayload.detectFormat('Receipt_2026.jpg'),
          equals(DocumentFormat.ocrImage));
      expect(DocumentPayload.detectFormat('Statement_Scan.png'),
          equals(DocumentFormat.ocrImage));
      expect(DocumentPayload.detectFormat('Paper_Bill.jpeg'),
          equals(DocumentFormat.ocrImage));
    });

    test('5. content:// URI handling: SafDocumentReader reads in-memory bytes',
        () async {
      final mockBytes = Uint8List.fromList(utf8.encode('Sample SAF Bytes'));
      final platformFile = PlatformFile(
        name:
            'content://com.android.providers.downloads.documents/document/123.pdf',
        size: mockBytes.length,
        bytes: mockBytes,
        path: null,
      );

      final readBytes = await SafDocumentReader.readBytes(platformFile);
      expect(readBytes, equals(mockBytes));
    });

    test('6. Cancelled picker: returns empty bytes when picker result is null',
        () async {
      final platformFile = PlatformFile(
        name: 'cancelled.pdf',
        size: 0,
        bytes: null,
        path: null,
      );

      final readBytes = await SafDocumentReader.readBytes(platformFile);
      expect(readBytes.isEmpty, isTrue);
    });

    test('7. Inaccessible/deleted URI: returns empty Uint8List safely',
        () async {
      final platformFile = PlatformFile(
        name: 'deleted_file.csv',
        size: 100,
        bytes: null,
        path: '/non_existent_directory_12345/deleted.csv',
      );

      final readBytes = await SafDocumentReader.readBytes(platformFile);
      expect(readBytes.isEmpty, isTrue);
    });

    test(
        '8. Duplicate statement import: detects duplicate transactions across imports',
        () async {
      const csvContent =
          'Date,Description,Amount,Type\n2026-08-01,Starbucks Coffee,350.00,DEBIT\n';
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(csvContent)),
        fileName: 'statement_july.csv',
        format: DocumentFormat.csv,
      );

      final firstImport =
          await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      final existingTxs = firstImport.items.map((e) => e.transaction).toList();

      final secondImport =
          await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: existingTxs,
      );

      expect(secondImport.items.first.isDuplicate, isTrue);
      expect(secondImport.health.duplicatesRemoved, equals(1));
    });

    test('9. Large statement processing: handles 1,000 rows cleanly', () async {
      final buffer = StringBuffer('Date,Description,Amount,Type\n');
      for (int i = 0; i < 1000; i++) {
        buffer.writeln('2026-08-01,Merchant Item $i,100.00,DEBIT');
      }

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
        fileName: 'large_statement_1000.csv',
        format: DocumentFormat.csv,
      );

      final stopwatch = Stopwatch()..start();
      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );
      stopwatch.stop();

      expect(result.items.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('10. Malformed file: handles invalid file content without throwing',
        () async {
      final payload = DocumentPayload(
        bytes: Uint8List.fromList([0xFF, 0xFE, 0x00, 0x00, 0x88, 0x99]),
        fileName: 'malformed_binary.pdf',
        format: DocumentFormat.pdf,
      );

      final result = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(result.items, isEmpty);
    });
  });
}
