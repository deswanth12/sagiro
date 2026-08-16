import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sagiro/services/saf_document_reader.dart';
import 'package:sagiro/services/csv_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android Storage Access Framework (SAF) File Readability Tests', () {
    test('1. Reads CSV file from Download/SBIYono/ location cleanly', () async {
      const content =
          'Date,Merchant,Amount,Type\n01/08/2026,SBI Yono Transfer,1500,Debit';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final file = PlatformFile(
        name: 'Download/SBIYono/SBI_Statement_Aug.csv',
        size: bytes.length,
        bytes: bytes,
        path: '/storage/emulated/0/Download/SBIYono/SBI_Statement_Aug.csv',
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);
      expect(result.text, contains('SBI Yono Transfer'));

      final parsed = CsvImporterService.parseCsv(result.text);
      expect(parsed.transactions.length, equals(1));
      expect(parsed.transactions.first.merchant, equals('SBI Yono Transfer'));
    });

    test('2. Reads CSV file from Android Files app content:// URI', () async {
      const content =
          'Date,Description,Withdrawal,Deposit\n05/08/2026,Salary Credit,,25000';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final file = PlatformFile(
        name: 'Statement_2026.csv',
        size: bytes.length,
        bytes: bytes,
        path:
            'content://com.android.providers.downloads.documents/document/raw%3A%2Fstorage%2Femulated%2F0%2FDownload%2FStatement.csv',
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);
      expect(result.text, contains('Salary Credit'));

      final parsed = CsvImporterService.parseCsv(result.text);
      expect(parsed.transactions.length, equals(1));
    });

    test('3. Reads CSV file from Documents location', () async {
      const content =
          'Date,Particulars,Debit,Credit\n10/08/2026,Rent Payment,8000,0';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final file = PlatformFile(
        name: 'Documents/Rent_Aug.csv',
        size: bytes.length,
        bytes: bytes,
        path: '/storage/emulated/0/Documents/Rent_Aug.csv',
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);
      expect(result.text, contains('Rent Payment'));
    });

    test('4. Reads file with spaces in filename cleanly', () async {
      const content = 'Date,Merchant,Amount\n11/08/2026,Swiggy Lunch,450';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final file = PlatformFile(
        name: 'SBI Bank Statement August 2026 Final.csv',
        size: bytes.length,
        bytes: bytes,
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);
      expect(
          result.fileName, equals('SBI Bank Statement August 2026 Final.csv'));
    });

    test('5. Reads file with Unicode characters in filename cleanly', () async {
      const content = 'Date,Merchant,Amount\n11/08/2026,Store Purchase ₹,1200';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final file = PlatformFile(
        name: 'ব্যাংক_বিবরণী_Statement_₹.csv',
        size: bytes.length,
        bytes: bytes,
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);
      expect(result.text, contains('Store Purchase ₹'));
    });

    test('6. Reads file with extremely long filename cleanly', () async {
      final longName = '${'A' * 120}.csv';
      const content = 'Date,Merchant,Amount\n11/08/2026,Merchant,100';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final file = PlatformFile(
        name: longName,
        size: bytes.length,
        bytes: bytes,
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);
    });

    test('7. Reads large CSV file (5,000 lines) performance benchmark',
        () async {
      final sb = StringBuffer();
      sb.writeln('Date,Merchant,Amount,Type');
      for (int i = 0; i < 5000; i++) {
        sb.writeln('01/08/2026,Merchant $i,${(i + 1) * 10},Debit');
      }

      final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
      final file = PlatformFile(
        name: 'Large_5k_Statement.csv',
        size: bytes.length,
        bytes: bytes,
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);

      final parsed = CsvImporterService.parseCsv(result.text);
      expect(parsed.transactions.length, equals(5000));
    });

    test('8. Decodes standard UTF-8 CSV cleanly', () async {
      const content = 'Date,Merchant,Amount\n01/08/2026,Cafe Coffee Day,220';
      final bytes = Uint8List.fromList(utf8.encode(content));

      final text = SafDocumentReader.decodeText(bytes);
      expect(text, equals(content));
    });

    test(
        '9. Decodes UTF-8 BOM CSV by stripping byte order mark \uFEFF automatically',
        () async {
      // UTF-8 BOM prefix: 0xEF, 0xBB, 0xBF
      const content = 'Date,Merchant,Amount\n01/08/2026,Zomato Order,350';
      final bomBytes =
          Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);

      final text = SafDocumentReader.decodeText(bomBytes);
      expect(text.startsWith('\uFEFF'), isFalse);
      expect(text.startsWith('Date'), isTrue);

      final parsed = CsvImporterService.parseCsv(text);
      expect(parsed.transactions.length, equals(1));
      expect(parsed.transactions.first.merchant, equals('Zomato Order'));
    });

    test(
        '10. Empty CSV (0 bytes) fails gracefully with user-friendly error message',
        () async {
      final file = PlatformFile(
        name: 'Empty_Statement.csv',
        size: 0,
        bytes: Uint8List(0),
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isFalse);
      expect(
          result.errorMessage, contains('Couldn\'t read Empty_Statement.csv'));
    });

    test('11. Corrupted / unparseable CSV fails gracefully without app crash',
        () async {
      const corruptedContent = r'INVALID_BINARY_JUNK_$$$%#%^#';
      final bytes = Uint8List.fromList(utf8.encode(corruptedContent));

      final file = PlatformFile(
        name: 'Corrupted.csv',
        size: bytes.length,
        bytes: bytes,
      );

      final result = await SafDocumentReader.validateAndRead(file);
      expect(result.isSuccess, isTrue);

      final parsed = CsvImporterService.parseCsv(result.text);
      expect(parsed.transactions.isEmpty, isTrue);
      expect(parsed.parseErrors, isNotEmpty);
    });
  });
}
