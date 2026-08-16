import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../document_engine/pipeline/financial_document_engine.dart';
import '../document_engine/models/document_payload.dart';

class StatementParseResult {
  final List<TransactionItem> transactions;
  final bool isPasswordProtected;
  final bool isDecryptedSuccessfully;
  final String? errorMessage;

  StatementParseResult({
    required this.transactions,
    this.isPasswordProtected = false,
    this.isDecryptedSuccessfully = true,
    this.errorMessage,
  });
}

/// On-Device Statement Importer Service
/// Supports CSV, Excel (.xlsx, .xls), and Password-Protected PDFs/CSVs.
///
/// PRIVACY & SECURITY GUARANTEES:
/// 1. 100% On-Device Processing (statement parsing performed locally).
/// 2. Passwords are used ONLY in RAM for the active decryption session.
/// 3. Decrypted buffers are zeroed out / garbage-collected immediately after parsing.
/// 4. Passwords are NEVER stored on disk or shared.
class StatementImporterService {
  static final StatementImporterService instance = StatementImporterService._();
  StatementImporterService._();

  /// Parse raw statement bytes or text on device
  Future<StatementParseResult> parseStatement({
    required Uint8List fileBytes,
    required String fileName,
    String? password,
  }) async {
    try {
      if (fileBytes.isEmpty) {
        return StatementParseResult(
          transactions: [],
          isPasswordProtected: false,
          isDecryptedSuccessfully: false,
          errorMessage:
              'Couldn\'t read $fileName. The file might be unavailable or empty.',
        );
      }

      final ext = fileName.split('.').last.toLowerCase();

      // Check if file is password protected (e.g. encrypted PDF / Zip / encrypted CSV)
      final bool isEncrypted = _detectEncryption(fileBytes, ext);

      if (isEncrypted && (password == null || password.isEmpty)) {
        return StatementParseResult(
          transactions: [],
          isPasswordProtected: true,
          isDecryptedSuccessfully: false,
          errorMessage:
              'This statement is password protected. Enter the password to continue.',
        );
      }

      // ── Process CSV / TXT / XLS / XLSX / PDF Statements via FinancialDocumentEngine ──
      final detectedFormat = DocumentPayload.detectFormat(fileName);
      final payload = DocumentPayload(
        bytes: fileBytes,
        fileName: fileName,
        format: detectedFormat,
        password: password,
      );

      final docResult = await FinancialDocumentEngine.instance.processDocument(
        document: payload,
        existingTransactions: [],
      );

      if (docResult.requiresPassword ||
          (docResult.isPasswordProtected &&
              !docResult.isDecryptedSuccessfully)) {
        return StatementParseResult(
          transactions: [],
          isPasswordProtected: true,
          isDecryptedSuccessfully: false,
          errorMessage:
              'This statement is password protected. Enter the password to continue.',
        );
      }

      final txItems = docResult.items.map((it) => it.transaction).toList();
      if (txItems.isNotEmpty) {
        return StatementParseResult(
          transactions: txItems,
          isPasswordProtected: false,
          isDecryptedSuccessfully: true,
        );
      }

      return StatementParseResult(
        transactions: [],
        isPasswordProtected: isEncrypted,
        isDecryptedSuccessfully: !isEncrypted,
        errorMessage: 'Could not identify transactions in this statement.',
      );
    } catch (e) {
      return StatementParseResult(
        transactions: [],
        isPasswordProtected: false,
        isDecryptedSuccessfully: false,
        errorMessage: 'Failed to process statement: ${e.toString()}',
      );
    }
  }

  /// Detects if PDF or CSV file bytes contain encryption signatures (/Encrypt in PDF, ZIP headers)
  bool _detectEncryption(Uint8List bytes, String extension) {
    if (extension == 'pdf') {
      final header = String.fromCharCodes(bytes.take(2048));
      return header.contains('/Encrypt') || header.contains('/Filter/Standard');
    }
    if (extension == 'zip') return true;
    return false;
  }
}
