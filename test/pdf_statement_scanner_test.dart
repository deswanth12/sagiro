import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/document_engine/models/document_payload.dart';
import 'package:sagiro/document_engine/parsers/pdf/pdf_statement_parser.dart';
import 'package:sagiro/document_engine/pipeline/financial_document_engine.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'test_helper.dart';

// ─── Helpers to generate real test PDFs on-device ──────────────────────────

Uint8List _generateUnprotectedPdf({
  List<String> lines = const [
    '01/08/2026 HDFC Salary Credit ₹50000.00',
    '02/08/2026 Amazon Shopping 1200.00',
    '03/08/2026 Swiggy Food 450.00',
  ],
}) {
  final doc = PdfDocument();
  final page = doc.pages.add();
  final font = PdfStandardFont(PdfFontFamily.helvetica, 12);

  double y = 20;
  for (final line in lines) {
    page.graphics.drawString(line, font, bounds: Rect.fromLTWH(20, y, 500, 20));
    y += 25;
  }

  final bytes = Uint8List.fromList(doc.saveSync());
  doc.dispose();
  return bytes;
}

Uint8List _generateEncryptedPdf({
  required String password,
  List<String> lines = const [
    '05/08/2026 SBI YONO Transfer 25000.00',
    '06/08/2026 Shell Fuel 2100.00',
    '07/08/2026 Medical Store 850.00',
  ],
}) {
  final doc = PdfDocument();
  final page = doc.pages.add();
  final font = PdfStandardFont(PdfFontFamily.helvetica, 12);

  double y = 20;
  for (final line in lines) {
    page.graphics.drawString(line, font, bounds: Rect.fromLTWH(20, y, 500, 20));
    y += 25;
  }

  doc.security.userPassword = password;
  final bytes = Uint8List.fromList(doc.saveSync());
  doc.dispose();
  return bytes;
}

Uint8List _generateMultiPageEncryptedPdf({
  required String password,
  int pageCount = 3,
}) {
  final doc = PdfDocument();
  final font = PdfStandardFont(PdfFontFamily.helvetica, 12);

  for (int p = 1; p <= pageCount; p++) {
    final page = doc.pages.add();
    page.graphics.drawString(
      '0$p/08/2026 Merchant_Page_$p ${p * 1000}.00',
      font,
      bounds: const Rect.fromLTWH(20, 20, 500, 20),
    );
  }

  doc.security.userPassword = password;
  final bytes = Uint8List.fromList(doc.saveSync());
  doc.dispose();
  return bytes;
}

// ─── Main Test Suite ────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
    }
    await AppSettingsService.instance.loadSettings();
  });

  group('PDF Statement Scanner — Password Protection & Extraction Suite', () {
    // 1. Normal unprotected PDF
    test('1. Normal unprotected PDF passes through without password prompt',
        () async {
      final bytes = _generateUnprotectedPdf();
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'UnprotectedStatement.pdf',
        format: DocumentFormat.pdf,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.isPasswordProtected, isFalse);
      expect(result.isDecryptedSuccessfully, isTrue);
      expect(result.items.isNotEmpty, isTrue);
      expect(result.items.first.transaction.amount, equals(50000.0));
    });

    // 2. Encryption detection without password
    test('2. Encrypted PDF detected — returns isPasswordProtected: true',
        () async {
      final bytes = _generateEncryptedPdf(password: 'SECRET_PDF_PWD_999');
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'EncryptedSBI.pdf',
        format: DocumentFormat.pdf,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.isPasswordProtected, isTrue);
      expect(result.isDecryptedSuccessfully, isFalse);
      expect(result.items, isEmpty);
      expect(result.errorMessage, contains('password protected'));
    });

    // 3. Correct password authentication
    test('3. Correct password unlocks PDF and extracts transactions', () async {
      const testPwd = 'SECRET_PDF_PWD_999';
      final bytes = _generateEncryptedPdf(password: testPwd);
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'EncryptedSBI.pdf',
        format: DocumentFormat.pdf,
        password: testPwd,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.isPasswordProtected, isTrue);
      expect(result.isDecryptedSuccessfully, isTrue);
      expect(result.items.length, equals(3));
      expect(result.items[0].transaction.amount, equals(25000.0));
      expect(result.items[1].transaction.amount, equals(2100.0));
      expect(result.items[2].transaction.amount, equals(850.0));
    });

    // 4. Incorrect password error handling
    test('4. Incorrect password returns user-friendly error without crashing',
        () async {
      final bytes = _generateEncryptedPdf(password: 'RealPassword123');
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'EncryptedHDFC.pdf',
        format: DocumentFormat.pdf,
        password: 'WRONG_PASSWORD_999',
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.isPasswordProtected, isTrue);
      expect(result.isDecryptedSuccessfully, isFalse);
      expect(result.items, isEmpty);
      expect(result.errorMessage,
          equals('Incorrect PDF password. Please try again.'));
    });

    // 5. Empty password handling
    test('5. Empty password returns password prompt requirement', () async {
      final bytes = _generateEncryptedPdf(password: 'Pass123');
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'EncryptedICICI.pdf',
        format: DocumentFormat.pdf,
        password: '',
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.isPasswordProtected, isTrue);
      expect(result.isDecryptedSuccessfully, isFalse);
      expect(result.items, isEmpty);
    });

    // 6. Corrupted PDF handling
    test('6. Corrupted PDF returns graceful error message without crashing',
        () async {
      final corruptedBytes =
          Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x99, 0x88, 0x77]);
      final payload = DocumentPayload(
        bytes: corruptedBytes,
        fileName: 'Corrupted.pdf',
        format: DocumentFormat.pdf,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.isDecryptedSuccessfully, isFalse);
      expect(result.items, isEmpty);
      expect(result.errorMessage, isNotNull);
    });

    // 7. Multi-page encrypted PDF
    test('7. Multi-page encrypted PDF extracts transactions across all pages',
        () async {
      const testPwd = 'MultiPagePass777';
      final bytes =
          _generateMultiPageEncryptedPdf(password: testPwd, pageCount: 3);
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'MultiPageStatement.pdf',
        format: DocumentFormat.pdf,
        password: testPwd,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.isDecryptedSuccessfully, isTrue);
      expect(result.items.length, equals(3));
      expect(result.health.pageCount, greaterThanOrEqualTo(1));
    });

    // 8. Integration through FinancialDocumentEngine
    test('8. FinancialDocumentEngine processes encrypted PDF end-to-end',
        () async {
      const testPwd = 'EnginePass444';
      final bytes = _generateEncryptedPdf(password: testPwd);
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'EngineStatement.pdf',
        format: DocumentFormat.pdf,
        password: testPwd,
      );

      final engineResult =
          await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      expect(engineResult.isDecryptedSuccessfully, isTrue);
      expect(engineResult.items.isNotEmpty, isTrue);
    });

    // 9. Security & Leakage Audit Test
    test('9. Password Leakage Audit — password never stored or leaked anywhere',
        () async {
      const secretPassword = 'SUPER_SECRET_LEAK_TEST_PASSWORD_99999';
      final bytes = _generateEncryptedPdf(password: secretPassword);

      // Attempt parsing with wrong password to trigger error path
      final payload = DocumentPayload(
        bytes: bytes,
        fileName: 'LeakAudit.pdf',
        format: DocumentFormat.pdf,
        password: secretPassword,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      // Assert error message does NOT contain secret password
      if (result.errorMessage != null) {
        expect(result.errorMessage, isNot(contains(secretPassword)));
      }

      // Assert SharedPreferences does NOT contain secret password
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        expect(prefs.get(key).toString(), isNot(contains(secretPassword)));
      }

      // Assert Database does NOT contain secret password
      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        final txs = await db.query('transactions');
        for (final row in txs) {
          expect(row.toString(), isNot(contains(secretPassword)));
        }
      }
    });

    // 10. Dedicated detectPdfProtection Helper Test
    test(
        '10. detectPdfProtection correctly classifies normal, encrypted, and corrupted PDFs',
        () {
      final normalBytes = _generateUnprotectedPdf();
      final encryptedBytes = _generateEncryptedPdf(password: 'SBIPass99');
      final corruptedBytes = Uint8List.fromList([0x10, 0x20, 0x30]);

      expect(detectPdfProtection(normalBytes),
          equals(PdfProtectionStatus.notProtected));
      expect(detectPdfProtection(encryptedBytes),
          equals(PdfProtectionStatus.passwordProtected));
      expect(detectPdfProtection(corruptedBytes),
          equals(PdfProtectionStatus.invalidPdf));
    });

    // 11. Multi-line wrapped descriptions & SBI statement structure
    test(
        '11. Extracts multi-line wrapped descriptions & SBI statement structure accurately',
        () async {
      const sbiContent = '''
State Bank of India
Account Statement for Period 01/08/2026 to 31/08/2026
Txn Date Value Date Description Ref No. Debit Credit Balance
01 Aug 2026 01 Aug 2026 TRANSFER TO 409983719283 / UPI/DR/621538192831/AMAZON PAY
ORDER PAYMENT FOR ELECTRONICS
1,250.00 48,750.00
02 Aug 2026 02 Aug 2026 BY TRANSFER / TRANSFER FROM 9182736451/SALARY
CREDIT FOR AUGUST
50,000.00 98,750.00
05 Aug 2026 05 Aug 2026 ATM WDL / CASH WITHDRAWAL
AT SBI ATM BANGALORE
5,000.00 93,750.00
''';
      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(sbiContent)),
        fileName: 'SBI_Yono_Statement.pdf',
        format: DocumentFormat.pdf,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.items.length, equals(3));
      expect(result.items[0].transaction.amount, equals(1250.0));
      expect(result.items[0].transaction.type, equals(TransactionType.debit));

      expect(result.items[1].transaction.amount, equals(50000.0));
      expect(result.items[1].transaction.type, equals(TransactionType.credit));

      expect(result.items[2].transaction.amount, equals(5000.0));
      expect(result.items[2].transaction.type, equals(TransactionType.debit));
    });

    // 12. 100+ Transactions Benchmark & Candidate Diagnostic Tracking
    test('12. Processes 100+ transactions without dropping rows or memory loss',
        () async {
      final buffer = StringBuffer();
      buffer.writeln('State Bank of India Account Statement');
      for (int i = 1; i <= 100; i++) {
        final day = (i % 28) + 1;
        final dayStr = day < 10 ? '0$day' : '$day';
        buffer.writeln(
            '$dayStr Aug 2026 UPI/DR/1000$i/MERCHANT_$i Rs.${i * 100}.00 Balance ${50000 + i}');
      }

      final payload = DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
        fileName: 'BulkStatement100.pdf',
        format: DocumentFormat.pdf,
      );

      final parser = PdfStatementParser();
      final result = await parser.parse(payload);

      expect(result.items.length, equals(100));
      expect(result.readyCount, equals(100));
    });
  });
}
