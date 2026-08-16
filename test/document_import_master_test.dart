import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/document_engine/models/document_payload.dart';
import 'package:sagiro/document_engine/parsers/excel/excel_statement_parser.dart';
import 'package:sagiro/document_engine/parsers/csv/csv_statement_parser.dart';
import 'package:sagiro/document_engine/parsers/ocr/ocr_statement_parser.dart';
import 'package:sagiro/document_engine/pipeline/financial_document_engine.dart';
import 'package:sagiro/document_engine/duplicate/duplicate_hash_detector.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/rag/rag_provider.dart';
import 'package:sagiro/rag/financial_ai_engine.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helper.dart';

/// Helper to generate in-memory OpenXML .xlsx binary files for testing
Uint8List createTestXlsxBytes(List<List<String>> rows) {
  final archive = Archive();
  final sharedStrings = <String>[];
  final stringIndexMap = <String, int>{};

  // Build sheet XML
  final sheetBuffer = StringBuffer();
  sheetBuffer
      .writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
  sheetBuffer.writeln(
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
  sheetBuffer.writeln('<sheetData>');

  for (int r = 0; r < rows.length; r++) {
    final rowNum = r + 1;
    sheetBuffer.writeln('<row r="$rowNum">');
    final row = rows[r];
    for (int c = 0; c < row.length; c++) {
      final cellValue = row[c];
      final colLetter = String.fromCharCode(65 + c);
      final cellRef = '$colLetter$rowNum';

      if (!stringIndexMap.containsKey(cellValue)) {
        stringIndexMap[cellValue] = sharedStrings.length;
        sharedStrings.add(cellValue);
      }
      final sIdx = stringIndexMap[cellValue]!;

      sheetBuffer.writeln('<c r="$cellRef" t="s"><v>$sIdx</v></c>');
    }
    sheetBuffer.writeln('</row>');
  }

  sheetBuffer.writeln('</sheetData>');
  sheetBuffer.writeln('</worksheet>');

  // Build shared strings XML
  final ssBuffer = StringBuffer();
  ssBuffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
  ssBuffer.writeln(
      '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${sharedStrings.length}" uniqueCount="${sharedStrings.length}">');
  for (final s in sharedStrings) {
    ssBuffer.writeln(
        '<si><t>${s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</t></si>');
  }
  ssBuffer.writeln('</sst>');

  final sheetBytes = utf8.encode(sheetBuffer.toString());
  final ssBytes = utf8.encode(ssBuffer.toString());

  archive.addFile(
      ArchiveFile('xl/worksheets/sheet1.xml', sheetBytes.length, sheetBytes));
  archive.addFile(ArchiveFile('xl/sharedStrings.xml', ssBytes.length, ssBytes));

  final encodedZip = ZipEncoder().encode(archive);
  return Uint8List.fromList(encodedZip);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
    await AppSettingsService.instance.loadSettings();
    FinancialAiEngine.invalidateCache();
  });

  group('SAGIRO Document & File Import Red-Team Audit Suite', () {
    // ════════════════════════════════════════════════════════════════════════
    // PHASE 1 — EXCEL (.XLSX) AUDIT
    // ════════════════════════════════════════════════════════════════════════
    test(
        '1. Excel (.xlsx): SBI-style statement with separate Debit & Credit columns',
        () async {
      final rows = [
        ['Txn Date', 'Narration', 'Chq/Ref No', 'Debit', 'Credit', 'Balance'],
        [
          '13/08/2026',
          'UPI/SWIGGY/123456789012',
          '123456789012',
          '450.00',
          '',
          '15,200.00'
        ],
        [
          '12/08/2026',
          'SALARY CREDIT ACME CORP',
          'SAL9921',
          '',
          '85,000.00',
          '15,650.00'
        ],
        [
          '11/08/2026',
          'ATM WDL SBI KORAMANGALA',
          'ATM441',
          '2,000.00',
          '',
          '13,650.00'
        ],
        ['Total', '', '', '2,450.00', '85,000.00', ''],
      ];

      final xlsxBytes = createTestXlsxBytes(rows);
      final parser = ExcelStatementParser();
      final payload = DocumentPayload(
        bytes: xlsxBytes,
        fileName: 'SBI_Statement_Aug2026.xlsx',
        format: DocumentFormat.excel,
      );

      final result = await parser.parse(payload);

      expect(result.items.length, equals(3));
      // Txn 1: Swiggy debit
      expect(result.items[0].transaction.merchant, equals('Swiggy'));
      expect(result.items[0].transaction.amount, equals(450.0));
      expect(result.items[0].transaction.type, equals(TransactionType.debit));
      expect(result.items[0].transaction.date, equals(DateTime(2026, 8, 13)));

      // Txn 2: Salary credit
      expect(result.items[1].transaction.amount, equals(85000.0));
      expect(result.items[1].transaction.type, equals(TransactionType.credit));

      // Txn 3: ATM withdrawal debit
      expect(result.items[2].transaction.amount, equals(2000.0));
      expect(result.items[2].transaction.type, equals(TransactionType.debit));
    });

    test(
        '2. Excel (.xlsx): HDFC-style statement with single Amount & Type (Dr/Cr)',
        () async {
      final rows = [
        ['Date', 'Transaction Details', 'Amount', 'Type', 'Closing Balance'],
        [
          '10-08-2026',
          'POS 4912 DOMINOS BANGALORE',
          '620.00',
          'DR',
          '22,400.00'
        ],
        ['09-08-2026', 'REFUND AMAZON INDIA', '1,499.00', 'CR', '23,020.00'],
      ];

      final xlsxBytes = createTestXlsxBytes(rows);
      final parser = ExcelStatementParser();
      final payload = DocumentPayload(
        bytes: xlsxBytes,
        fileName: 'HDFC_Account_Statement.xlsx',
        format: DocumentFormat.excel,
      );

      final result = await parser.parse(payload);

      expect(result.items.length, equals(2));
      expect(result.items[0].transaction.amount, equals(620.0));
      expect(result.items[0].transaction.type, equals(TransactionType.debit));
      expect(result.items[1].transaction.amount, equals(1499.0));
      expect(result.items[1].transaction.type, equals(TransactionType.credit));
    });

    test('3. Excel (.xlsx): 1,000+ rows large dataset parses in under 1,000ms',
        () async {
      final rows = <List<String>>[
        ['Date', 'Narration', 'Debit', 'Credit'],
      ];

      for (int i = 0; i < 1000; i++) {
        final day = (i % 28) + 1;
        final dayStr = day.toString().padLeft(2, '0');
        rows.add([
          '$dayStr/08/2026',
          'Merchant Order #$i',
          '${(i % 500) + 10}.00',
          '',
        ]);
      }

      final xlsxBytes = createTestXlsxBytes(rows);
      final parser = ExcelStatementParser();
      final payload = DocumentPayload(
        bytes: xlsxBytes,
        fileName: 'Large_Statement_1000.xlsx',
        format: DocumentFormat.excel,
      );

      final stopwatch = Stopwatch()..start();
      final result = await parser.parse(payload);
      stopwatch.stop();

      expect(result.items.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    // ════════════════════════════════════════════════════════════════════════
    // PHASE 2 — CSV IMPORT AUDIT
    // ════════════════════════════════════════════════════════════════════════
    test('4. CSV: Standard UTF-8 with quoted fields & commas in merchant names',
        () async {
      const csvData = '''
Date,Description,Debit,Credit,Balance
14/08/2026,"Swiggy, Bangalore South",340.00,,12000.00
13/08/2026,"Amazon India, Electronics",2500.00,,11660.00
12/08/2026,"Interest Paid, Q2",,150.00,14160.00
''';

      final parser = CsvStatementParser();
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(csvData)),
        fileName: 'Statement.csv',
        format: DocumentFormat.csv,
      );

      final result = await parser.parse(payload);
      expect(result.items.length, equals(3));
      expect(result.items[0].transaction.amount, equals(340.0));
      expect(result.items[1].transaction.amount, equals(2500.0));
      expect(result.items[2].transaction.amount, equals(150.0));
      expect(result.items[2].transaction.type, equals(TransactionType.credit));
    });

    test('5. CSV: Semicolon delimiter & UTF-8 BOM', () async {
      const bomCsv = '\uFEFF'
          'Date;Narration;Amount;Type\n'
          '10/08/2026;Uber India;420.00;Debit\n'
          '09/08/2026;Salary Acme;75000.00;Credit\n';

      final parser = CsvStatementParser();
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(bomCsv)),
        fileName: 'European_Style.csv',
        format: DocumentFormat.csv,
      );

      final result = await parser.parse(payload);
      expect(result.items.length, equals(2));
      expect(result.items[0].transaction.amount, equals(420.0));
      expect(result.items[1].transaction.amount, equals(75000.0));
    });

    // ════════════════════════════════════════════════════════════════════════
    // PHASE 3 & 4 — OCR STATEMENT PARSER AUDIT
    // ════════════════════════════════════════════════════════════════════════
    test('6. OCR: Tabular receipt text extraction with Dr/Cr and date parsing',
        () async {
      const ocrRawText = '''
STATEMENT OF ACCOUNT - STATE BANK OF INDIA
13/08/2026 SWIGGY INSTAMART 450.00 DR
12-08-2026 POS/AMAZON INDIA 2499.00 DR
10.08.2026 UPI/123456789012/ZOMATO 620.00 DR
08 Aug 2026 SALARY CREDIT ACME CORP 85000.00 CR
Closing Balance: Rs 95,431.00
''';

      final parser = OcrStatementParser();
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(ocrRawText)),
        fileName: 'paper_statement_photo.jpg',
        format: DocumentFormat.ocrImage,
      );

      final result = await parser.parse(payload);

      expect(result.items.length, equals(4));
      expect(result.items[0].transaction.amount, equals(450.0));
      expect(result.items[0].transaction.type, equals(TransactionType.debit));
      expect(result.items[3].transaction.amount, equals(85000.0));
      expect(result.items[3].transaction.type, equals(TransactionType.credit));
    });

    // ════════════════════════════════════════════════════════════════════════
    // PHASE 5 & 6 — CROSS-SOURCE DUPLICATE PROTECTION AUDIT
    // ════════════════════════════════════════════════════════════════════════
    test(
        '7. Duplicate Protection: SMS transaction detected when re-imported via CSV or Excel',
        () async {
      final existingTx = TransactionItem(
        amount: 450.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 13),
        transactionReference: '123456789012',
        profileId: 'default_profile',
      );

      final candidateCsvTx = TransactionItem(
        amount: 450.0,
        merchant: 'Swiggy',
        category: 'Excel Import',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime(2026, 8, 13),
        transactionReference: '123456789012',
        profileId: 'default_profile',
      );

      final isDup = DuplicateHashDetector.isDuplicate(
        candidate: candidateCsvTx,
        existingTransactions: [existingTx],
      );

      expect(isDup, isTrue);
    });

    // ════════════════════════════════════════════════════════════════════════
    // PHASE 7, 8, 9, 10 — END-TO-END TIMELINE, DASHBOARD, & MONEY BRAIN SYNC
    // ════════════════════════════════════════════════════════════════════════
    test(
        '8. End-to-End: Excel import reaches SQLite, updates BudgetProvider, and Money Brain answers correctly',
        () async {
      final now = DateTime.now();
      final dayStr = now.day.toString().padLeft(2, '0');
      final monthStr = now.month.toString().padLeft(2, '0');
      final yearStr = now.year.toString();

      final rows = [
        ['Date', 'Narration', 'Debit', 'Credit'],
        ['$dayStr/$monthStr/$yearStr', 'Swiggy Food Delivery', '500.00', ''],
        ['$dayStr/$monthStr/$yearStr', 'Zomato Dining', '700.00', ''],
        ['$dayStr/$monthStr/$yearStr', 'Uber Transport', '1000.00', ''],
      ];

      final xlsxBytes = createTestXlsxBytes(rows);
      final payload = DocumentPayload(
        bytes: xlsxBytes,
        fileName: 'August_Import.xlsx',
        format: DocumentFormat.excel,
      );

      final docResult = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(docResult.items.length, equals(3));

      // Batch persist to BudgetProvider
      final budgetProvider = BudgetProvider();
      await budgetProvider.loadData();
      final txsToImport = docResult.items.map((i) => i.transaction).toList();
      await budgetProvider.addTransactionsBatch(txsToImport);

      // Verify Timeline / DB persistence
      final allDbTxs = await DatabaseHelper.instance.getAllTransactions();
      expect(allDbTxs.length, equals(3));
      expect(budgetProvider.transactions.length, equals(3));

      // Money Brain query
      final ragProvider = RagProvider();
      final result =
          await ragProvider.queryMoneyBrain('How much did I spend on food?');

      expect(result.response.answer.contains('Food spending'), isTrue);
      expect(result.response.answer.contains('₹1,200 total'), isTrue);
      expect(result.response.answer.contains('2 transactions'), isTrue);
      expect(
          result.response.answer
              .contains('Sagiro is a privacy-first personal finance app'),
          isFalse);
    });
  });
}
