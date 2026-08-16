import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../document_engine/duplicate/duplicate_hash_detector.dart';

enum CsvRowDisposition {
  imported,
  duplicate,
  invalid,
  needsReview,
  headerSummary,
}

class CsvRowStatus {
  final int rowNumber; // 1-indexed line number in original CSV file
  final String rawLine; // Original raw line from CSV
  final TransactionItem? transaction;
  final CsvRowDisposition status;
  final String reason;
  final String? bankReference;

  const CsvRowStatus({
    required this.rowNumber,
    required this.rawLine,
    this.transaction,
    required this.status,
    required this.reason,
    this.bankReference,
  });
}

/// Result of a CSV import operation with 100% Source-to-Import Reconciliation.
class CsvImportResult {
  final int totalLinesInFile;
  final int headerAndSummaryRows;
  final int totalSourceDataRows;
  final List<TransactionItem> transactions;
  final List<CsvRowStatus> rowStatuses;
  final List<String> parseErrors;
  final List<TransactionItem> duplicates;
  final List<TransactionItem> needsReview;

  const CsvImportResult({
    required this.totalLinesInFile,
    required this.headerAndSummaryRows,
    required this.totalSourceDataRows,
    required this.transactions,
    required this.rowStatuses,
    required this.parseErrors,
    required this.duplicates,
    required this.needsReview,
  });

  int get validTransactionsCount => transactions.length;
  int get duplicateCount => duplicates.length;
  int get invalidCount =>
      rowStatuses.where((r) => r.status == CsvRowDisposition.invalid).length;
  int get needsReviewCount => needsReview.length;

  /// Strict Source-to-Import Reconciliation Equation:
  /// Source Data Rows = Imported + Duplicates + Invalid + Needs Review
  bool get reconciles =>
      totalSourceDataRows ==
      (validTransactionsCount +
          duplicateCount +
          invalidCount +
          needsReviewCount);

  // Backward compatibility getters
  int get skippedRows => duplicateCount + invalidCount + needsReviewCount;
}

/// CsvImporterService — Parses bank statement CSVs into TransactionItems
/// with ZERO Silent Data Loss and 100% Source Reconciliation.
class CsvImporterService {
  static const int kMaxRows = 50000;

  static CsvImportResult parseCsv(
    String csvContent, {
    String fileName = 'Statement.csv',
    List<TransactionItem> existingTransactions = const [],
  }) {
    // ── Strip UTF-8 BOM if present ──────────────────────────────────────
    var cleanContent = csvContent;
    if (cleanContent.startsWith('\uFEFF')) {
      cleanContent = cleanContent.substring(1);
    }

    final normalized =
        cleanContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // ── Auto-detect field delimiter (comma, semicolon, tab) ─────────────
    String fieldDelimiter = ',';
    final sampleLines = normalized
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(10)
        .toList();
    if (sampleLines.isNotEmpty) {
      int commaCount = 0;
      int semiCount = 0;
      int tabCount = 0;
      for (final line in sampleLines) {
        commaCount += ','.allMatches(line).length;
        semiCount += ';'.allMatches(line).length;
        tabCount += '\t'.allMatches(line).length;
      }
      if (semiCount > commaCount && semiCount > tabCount) {
        fieldDelimiter = ';';
      } else if (tabCount > commaCount && tabCount > semiCount) {
        fieldDelimiter = '\t';
      }
    }

    final rawConvertedRows = CsvToListConverter(
      eol: '\n',
      fieldDelimiter: fieldDelimiter,
    ).convert(normalized);

    final List<List<dynamic>> rows = rawConvertedRows
        .where(
            (r) => r.isNotEmpty && r.any((c) => c.toString().trim().isNotEmpty))
        .toList();

    final rawLines =
        normalized.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final totalLines = rawLines.length;

    if (rows.isEmpty || rows.length < 2) {
      return CsvImportResult(
        totalLinesInFile: totalLines,
        headerAndSummaryRows: totalLines,
        totalSourceDataRows: 0,
        transactions: [],
        rowStatuses: [],
        parseErrors: ['File is empty or has no data rows.'],
        duplicates: [],
        needsReview: [],
      );
    }

    // ── Step 1: Dynamic Header Row Auto-Detection (Scan first 15 rows) ──
    int headerRowIndex = 0;
    int maxHeaderScore = -1;
    List<String> headers = [];

    final scanLimit = rows.length > 15 ? 15 : rows.length;
    for (int r = 0; r < scanLimit; r++) {
      final candidateHeaders =
          rows[r].map((e) => e.toString().toLowerCase().trim()).toList();
      final score = _evaluateHeaderScore(candidateHeaders);
      if (score > maxHeaderScore) {
        maxHeaderScore = score;
        headerRowIndex = r;
        headers = candidateHeaders;
      }
    }

    final dateIdx = _findHeaderIndex(headers, [
      'date',
      'txn date',
      'transaction date',
      'value date',
      'posting date',
      'tran date'
    ]);

    final debitIdx = _findHeaderIndex(headers, [
      'debit amount',
      'debit',
      'withdrawal amt',
      'withdrawal amount',
      'dr amt',
      'withdrawal',
      'dr'
    ]);

    final creditIdx = _findHeaderIndex(headers, [
      'credit amount',
      'credit',
      'deposit amt',
      'deposit amount',
      'cr amt',
      'deposit',
      'cr'
    ]);

    final amountIdx = _findHeaderIndex(headers,
        ['amount', 'txn amount', 'value', 'net amount', 'transaction amount']);

    final merchantIdx = _findHeaderIndex(headers, [
      'merchant',
      'narration',
      'description',
      'particulars',
      'details',
      'transaction details',
      'remarks'
    ]);

    final typeIdx = _findHeaderIndex(headers,
        ['type', 'cr/dr', 'debit/credit', 'transaction type', 'dr/cr']);

    final refIdx = _findHeaderIndex(headers, [
      'ref',
      'ref no',
      'ref. no.',
      'ref num',
      'reference',
      'cheque no',
      'chq no',
      'utr',
      'txn id',
      'transaction id'
    ]);

    final List<TransactionItem> validTransactions = [];
    final List<TransactionItem> duplicates = [];
    final List<TransactionItem> needsReview = [];
    final List<CsvRowStatus> rowStatuses = [];
    final List<String> errors = [];

    int headerAndSummaryCount = 0;

    // Record pre-header and header rows as headerSummary
    for (int i = 0; i <= headerRowIndex; i++) {
      headerAndSummaryCount++;
      final lineContent = i < rawLines.length ? rawLines[i] : '';
      rowStatuses.add(CsvRowStatus(
        rowNumber: i + 1,
        rawLine: lineContent,
        status: CsvRowDisposition.headerSummary,
        reason: i == headerRowIndex
            ? 'Header Row (Detected column mapping)'
            : 'Pre-header file metadata / bank title',
      ));
    }

    final int limit = rows.length > kMaxRows ? kMaxRows : rows.length;

    // ── Step 2: Process Data Rows ──────────────────────────────────────────
    for (int i = headerRowIndex + 1; i < limit; i++) {
      final rowNumber = i + 1;
      final rawLine = i < rawLines.length ? rawLines[i] : '';
      final row = rows[i];

      // Empty / whitespace row check
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        headerAndSummaryCount++;
        continue;
      }

      // Skip total summary lines explicitly
      final rowTextLower = rawLine.toLowerCase();
      if (rowTextLower.contains('total:') ||
          rowTextLower.contains('closing balance') ||
          rowTextLower.contains('opening balance') ||
          rowTextLower.startsWith('total') ||
          rowTextLower.startsWith('summary') ||
          rowTextLower.startsWith('opening bal') ||
          rowTextLower.startsWith('closing bal')) {
        headerAndSummaryCount++;
        rowStatuses.add(CsvRowStatus(
          rowNumber: rowNumber,
          rawLine: rawLine,
          status: CsvRowDisposition.headerSummary,
          reason: 'Statement summary total / balance row.',
        ));
        continue;
      }

      try {
        final rawDate = dateIdx != -1 && dateIdx < row.length
            ? row[dateIdx].toString().trim()
            : '';
        final rawMerchant = merchantIdx != -1 && merchantIdx < row.length
            ? row[merchantIdx].toString().trim()
            : '';
        final rawType = typeIdx != -1 && typeIdx < row.length
            ? row[typeIdx].toString().toLowerCase().trim()
            : '';
        final rawRef = refIdx != -1 && refIdx < row.length
            ? row[refIdx].toString().trim()
            : '';

        // ── Date Parsing & Validation ──────────────────────────────────
        if (rawDate.isEmpty) {
          final reason =
              'Row $rowNumber: Skipped because date field is missing.';
          errors.add(reason);
          rowStatuses.add(CsvRowStatus(
            rowNumber: rowNumber,
            rawLine: rawLine,
            status: CsvRowDisposition.invalid,
            reason: reason,
          ));
          continue;
        }

        final DateTime? parsedDate = _parseDate(rawDate);
        if (parsedDate == null) {
          final reason =
              'Row $rowNumber: Skipped because date format "$rawDate" is unparseable.';
          errors.add(reason);
          rowStatuses.add(CsvRowStatus(
            rowNumber: rowNumber,
            rawLine: rawLine,
            status: CsvRowDisposition.invalid,
            reason: reason,
          ));
          continue;
        }

        // ── Amount & Debit/Credit Parsing ──────────────────────────────
        double finalAmount = 0.0;
        TransactionType finalType = TransactionType.debit;

        double debitVal = 0.0;
        double creditVal = 0.0;

        if (debitIdx != -1 && debitIdx < row.length) {
          debitVal = _parseRawAmount(row[debitIdx].toString());
        }
        if (creditIdx != -1 && creditIdx < row.length) {
          creditVal = _parseRawAmount(row[creditIdx].toString());
        }

        if (debitVal > 0) {
          finalAmount = debitVal;
          finalType = TransactionType.debit;
        } else if (creditVal > 0) {
          finalAmount = creditVal;
          finalType = TransactionType.credit;
        } else if (amountIdx != -1 && amountIdx < row.length) {
          final rawVal = row[amountIdx].toString();
          final parsedVal = _parseSignedAmount(rawVal);

          if (parsedVal < 0) {
            finalAmount = parsedVal.abs();
            finalType = TransactionType.debit;
          } else {
            finalAmount = parsedVal;
            if (rawType.contains('credit') ||
                rawType.contains('cr') ||
                rawType.contains('deposit')) {
              finalType = TransactionType.credit;
            } else {
              finalType = TransactionType.debit;
            }
          }
        }

        if (finalAmount <= 0) {
          final reason =
              'Row $rowNumber: Skipped because amount is missing or zero.';
          errors.add(reason);
          rowStatuses.add(CsvRowStatus(
            rowNumber: rowNumber,
            rawLine: rawLine,
            status: CsvRowDisposition.invalid,
            reason: reason,
          ));
          continue;
        }

        // Override type if rawType explicitly indicates CR or DR
        if (rawType.contains('credit') ||
            rawType == 'cr' ||
            rawType.contains('deposit')) {
          finalType = TransactionType.credit;
        } else if (rawType.contains('debit') ||
            rawType == 'dr' ||
            rawType.contains('withdrawal')) {
          finalType = TransactionType.debit;
        }

        final merchant =
            rawMerchant.isEmpty ? 'CSV Import' : rawMerchant.trim();
        final refId = rawRef.isNotEmpty ? rawRef : 'ROW-$rowNumber';
        final category = _inferCategory(merchant);

        final transaction = TransactionItem(
          amount: finalAmount,
          merchant: merchant,
          category: category,
          type: finalType,
          source: TransactionSource.csv,
          date: parsedDate,
          rawSms: null,
          transactionReference: rawRef.isNotEmpty ? rawRef : null,
          notes:
              'Original Narration: $merchant | Ref: $refId | Row: $rowNumber',
        );

        // ── Duplicate Check via Ref & Frequency Audit ─────────────────
        final isDup = DuplicateHashDetector.isDuplicate(
          candidate: transaction,
          existingTransactions: existingTransactions,
          currentBatch: validTransactions,
        );

        if (isDup) {
          duplicates.add(transaction);
          rowStatuses.add(CsvRowStatus(
            rowNumber: rowNumber,
            rawLine: rawLine,
            transaction: transaction,
            status: CsvRowDisposition.duplicate,
            reason:
                'Row $rowNumber: Already imported duplicate transaction (Ref: $refId).',
            bankReference: refId,
          ));
        } else {
          validTransactions.add(transaction);
          rowStatuses.add(CsvRowStatus(
            rowNumber: rowNumber,
            rawLine: rawLine,
            transaction: transaction,
            status: CsvRowDisposition.imported,
            reason: 'Row $rowNumber: Valid transaction ready for import.',
            bankReference: refId,
          ));
        }
      } catch (e) {
        final reason =
            'Row $rowNumber: Parsing exception — ${e.toString().split('\n').first}';
        errors.add(reason);
        rowStatuses.add(CsvRowStatus(
          rowNumber: rowNumber,
          rawLine: rawLine,
          status: CsvRowDisposition.invalid,
          reason: reason,
        ));
      }
    }

    final totalSourceDataRows = totalLines - headerAndSummaryCount;

    return CsvImportResult(
      totalLinesInFile: totalLines,
      headerAndSummaryRows: headerAndSummaryCount,
      totalSourceDataRows: totalSourceDataRows < 0 ? 0 : totalSourceDataRows,
      transactions: validTransactions,
      rowStatuses: rowStatuses,
      parseErrors: errors,
      duplicates: duplicates,
      needsReview: needsReview,
    );
  }

  static double _parseRawAmount(String raw) {
    var cleaned = raw
        .replaceAll(',', '')
        .replaceAll('Rs', '')
        .replaceAll('₹', '')
        .replaceAll('\$', '')
        .replaceAll('INR', '')
        .replaceAll('\uFFFD', '')
        .replaceAll(RegExp(r'[^0-9\.\-\(\)]'), '')
        .trim();
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      cleaned = '-${cleaned.substring(1, cleaned.length - 1)}';
    }
    final val = double.tryParse(cleaned) ?? 0.0;
    return val.abs();
  }

  static double _parseSignedAmount(String raw) {
    var cleaned = raw
        .replaceAll(',', '')
        .replaceAll('Rs', '')
        .replaceAll('₹', '')
        .replaceAll('\$', '')
        .replaceAll('INR', '')
        .replaceAll('\uFFFD', '')
        .replaceAll(RegExp(r'[^0-9\.\-\(\)]'), '')
        .trim();
    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      cleaned = '-${cleaned.substring(1, cleaned.length - 1)}';
    }
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime? _parseDate(String raw) {
    // Strip time component if present e.g. "11/08/2026 14:30:00" -> "11/08/2026"
    var cleaned = raw.trim();
    if (cleaned.contains(' ')) {
      cleaned = cleaned.split(' ').first.trim();
    }
    if (cleaned.contains('T')) {
      cleaned = cleaned.split('T').first.trim();
    }
    cleaned = cleaned.replaceAll('.', '/').replaceAll('-', '/');

    final formats = [
      DateFormat('dd/MM/yyyy'),
      DateFormat('d/M/yyyy'),
      DateFormat('dd/MMM/yyyy'),
      DateFormat('d/MMM/yyyy'),
      DateFormat('dd/MMM/yy'),
      DateFormat('d/MMM/yy'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('MM/dd/yyyy'),
    ];

    for (final fmt in formats) {
      try {
        final parsed = fmt.parseStrict(cleaned);
        if (parsed.year < 2000 || parsed.year > 2100) continue;
        return parsed;
      } catch (_) {}
    }

    final iso = DateTime.tryParse(raw.trim());
    if (iso != null && iso.year >= 2000 && iso.year <= 2100) return iso;

    return null;
  }

  static int _evaluateHeaderScore(List<String> candidateHeaders) {
    int score = 0;
    final text = candidateHeaders.join(' ');
    if (text.contains('date')) score += 3;
    if (text.contains('amount') ||
        text.contains('debit') ||
        text.contains('credit')) score += 3;
    if (text.contains('narration') ||
        text.contains('description') ||
        text.contains('merchant') ||
        text.contains('particulars')) score += 3;
    if (text.contains('ref') ||
        text.contains('chq') ||
        text.contains('balance')) score += 1;
    return score;
  }

  static int _findHeaderIndex(List<String> headers, List<String> candidates) {
    for (var cand in candidates) {
      final idx = headers.indexWhere((h) => h.contains(cand));
      if (idx != -1) return idx;
    }
    return -1;
  }

  static String _inferCategory(String merchant) {
    final lower = merchant.toLowerCase();
    if (lower.contains('swiggy') ||
        lower.contains('zomato') ||
        lower.contains('food') ||
        lower.contains('restaurant')) {
      return 'Food';
    }
    if (lower.contains('petrol') ||
        lower.contains('fuel') ||
        lower.contains('hpcl') ||
        lower.contains('bpcl') ||
        lower.contains('indian oil')) {
      return 'Fuel';
    }
    if (lower.contains('amazon') ||
        lower.contains('flipkart') ||
        lower.contains('myntra') ||
        lower.contains('shopping')) {
      return 'Shopping';
    }
    if (lower.contains('salary')) return 'Salary';
    if (lower.contains('emi') ||
        lower.contains('rent') ||
        lower.contains('loan')) {
      return 'EMI';
    }
    if (lower.contains('blinkit') ||
        lower.contains('zepto') ||
        lower.contains('grocer') ||
        lower.contains('supermarket')) {
      return 'Groceries';
    }
    return 'General';
  }
}
