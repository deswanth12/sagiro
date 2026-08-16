import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sagiro/services/saf_document_reader.dart';
import 'package:sagiro/services/statement_importer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Format (PDF, XLS, XLSX) SAF File Readability Tests', () {
    test('1. Validates PDF statement selected from Download/SBIYono/ location',
        () async {
      const samplePdfText =
          'Date,Merchant,Amount,Type\n01/08/2026,SBI Yono PDF Txn,2500,Debit';
      final bytes = Uint8List.fromList(utf8.encode(samplePdfText));

      final file = PlatformFile(
        name: 'Download/SBIYono/SBI_Statement.pdf',
        size: bytes.length,
        bytes: bytes,
      );

      final readResult = await SafDocumentReader.validateAndRead(file);
      expect(readResult.isSuccess, isTrue);

      final parseResult =
          await StatementImporterService.instance.parseStatement(
        fileBytes: readResult.bytes,
        fileName: readResult.fileName,
      );
      expect(parseResult.transactions.length, equals(1));
      expect(
          parseResult.transactions.first.merchant, equals('SBI Yono PDF Txn'));
    });

    test('2. Validates XLS/XLSX statement selected from Documents location',
        () async {
      const sampleExcelText =
          'Date,Merchant,Amount,Type\n05/08/2026,HDFC Excel Salary,35000,Credit';
      final bytes = Uint8List.fromList(utf8.encode(sampleExcelText));

      final file = PlatformFile(
        name: 'Documents/HDFC_Aug_2026.xlsx',
        size: bytes.length,
        bytes: bytes,
      );

      final readResult = await SafDocumentReader.validateAndRead(file);
      expect(readResult.isSuccess, isTrue);

      final parseResult =
          await StatementImporterService.instance.parseStatement(
        fileBytes: readResult.bytes,
        fileName: readResult.fileName,
      );
      expect(parseResult.transactions.length, equals(1));
      expect(
          parseResult.transactions.first.merchant, equals('HDFC Excel Salary'));
    });

    test('3. Empty PDF (0 bytes) fails gracefully with clear error message',
        () async {
      final file = PlatformFile(
        name: 'Empty_Statement.pdf',
        size: 0,
        bytes: Uint8List(0),
      );

      final readResult = await SafDocumentReader.validateAndRead(file);
      expect(readResult.isSuccess, isFalse);

      final parseResult =
          await StatementImporterService.instance.parseStatement(
        fileBytes: readResult.bytes,
        fileName: readResult.fileName,
      );
      expect(parseResult.transactions.isEmpty, isTrue);
      expect(parseResult.errorMessage,
          contains('Couldn\'t read Empty_Statement.pdf'));
    });

    test(
        '4. Empty XLS/XLSX (0 bytes) fails gracefully with clear error message',
        () async {
      final file = PlatformFile(
        name: 'Empty_Statement.xlsx',
        size: 0,
        bytes: Uint8List(0),
      );

      final readResult = await SafDocumentReader.validateAndRead(file);
      expect(readResult.isSuccess, isFalse);

      final parseResult =
          await StatementImporterService.instance.parseStatement(
        fileBytes: readResult.bytes,
        fileName: readResult.fileName,
      );
      expect(parseResult.transactions.isEmpty, isTrue);
      expect(parseResult.errorMessage,
          contains('Couldn\'t read Empty_Statement.xlsx'));
    });

    test('5. PDF file with spaces and Unicode in filename is readable',
        () async {
      const sampleText = 'Date,Merchant,Amount\n10/08/2026,Rent Payment,8000';
      final bytes = Uint8List.fromList(utf8.encode(sampleText));

      final file = PlatformFile(
        name: 'SBI Bank Statement (ব্যাংক_বিবরণী) ₹.pdf',
        size: bytes.length,
        bytes: bytes,
      );

      final readResult = await SafDocumentReader.validateAndRead(file);
      expect(readResult.isSuccess, isTrue);

      final parseResult =
          await StatementImporterService.instance.parseStatement(
        fileBytes: readResult.bytes,
        fileName: readResult.fileName,
      );
      expect(parseResult.transactions.length, equals(1));
    });

    test(
        '6. Corrupted PDF/Excel binary content handles error without app crash',
        () async {
      const corruptedText = r'INVALID_PDF_BINARY_STREAM_JUNK_$%^&*#';
      final bytes = Uint8List.fromList(utf8.encode(corruptedText));

      final file = PlatformFile(
        name: 'Corrupted.pdf',
        size: bytes.length,
        bytes: bytes,
      );

      final parseResult =
          await StatementImporterService.instance.parseStatement(
        fileBytes: bytes,
        fileName: file.name,
      );
      expect(parseResult.transactions.isEmpty, isTrue);
    });
  });
}
