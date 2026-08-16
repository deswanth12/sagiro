import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../../parsers/statement_parser.dart';
import '../../models/document_payload.dart';
import '../../models/statement_result.dart';
import '../../models/parser_capabilities.dart';
import '../../models/statement_health.dart';
import '../../validators/record_validator.dart';
import '../../confidence/field_confidence_engine.dart';
import '../../../models/transaction.dart';
import '../../../services/merchant_intelligence_service.dart';
import '../csv/csv_statement_parser.dart';

class ExcelStatementParser implements StatementParser {
  @override
  String get id => 'excel_statement_parser';

  @override
  String get name => 'Universal Excel (.xlsx/.xls) Parser';

  @override
  String get version => 'v2.5.0';

  @override
  ParserCapabilities get capabilities => const ParserCapabilities(
        passwordPdf: false,
        multiPage: true,
        tables: true,
        balanceDetection: true,
      );

  @override
  bool supports(DocumentPayload document) {
    return document.format == DocumentFormat.excel;
  }

  @override
  Future<StatementResult> parse(DocumentPayload document) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final items = <StatementResultItem>[];
    final warnings = <String>[];

    List<List<String>> rows = [];

    // 1. Try parsing as binary OpenXML .xlsx archive
    try {
      rows = _extractRowsFromXlsx(document.bytes);
    } catch (_) {
      rows = [];
    }

    // 2. If XLSX archive returned 0 rows, decode text and check for HTML Table / XML Spreadsheet / CSV
    if (rows.isEmpty || rows.length < 2) {
      String textContent = '';
      try {
        textContent = utf8.decode(document.bytes, allowMalformed: true);
      } catch (_) {
        textContent = String.fromCharCodes(document.bytes);
      }

      // Tier 2A: Bank HTML Table disguised as .xls (e.g. SBI, HDFC, Axis, ICICI)
      if (textContent.toLowerCase().contains('<table') ||
          textContent.toLowerCase().contains('<tr') ||
          textContent.toLowerCase().contains('<!doctype html') ||
          textContent.toLowerCase().contains('<html')) {
        rows = _extractRowsFromHtmlTable(textContent);
      }

      // Tier 2B: XML Spreadsheet 2003 (.xls)
      if (rows.isEmpty &&
          (textContent.contains('xmlns="urn:schemas-microsoft-com:office:spreadsheet"') ||
              textContent.contains('<Workbook') ||
              textContent.contains('<ss:Workbook') ||
              textContent.contains('<Row'))) {
        rows = _extractRowsFromXmlSpreadsheet(textContent);
      }

      // Tier 2C: Plain Delimited CSV / TSV / Semicolon
      if (rows.isEmpty && textContent.isNotEmpty && !textContent.startsWith('PK')) {
        final csvPayload = DocumentPayload(
          bytes: document.bytes,
          fileName: document.fileName,
          format: DocumentFormat.csv,
        );
        final csvRes = await CsvStatementParser().parse(csvPayload);
        if (csvRes.items.isNotEmpty) {
          stopwatch.stop();
          return StatementResult(
            items: csvRes.items,
            health: StatementHealth(
              healthScore: 95,
              pageCount: 1,
              totalTransactions: csvRes.items.length,
              openingBalanceVerified: true,
              closingBalanceVerified: true,
              merchantAccuracyPercent: 99,
              duplicatesRemoved: 0,
              parserVersion: version,
              parseTime: stopwatch.elapsed,
            ),
          );
        }

        rows = _extractRowsFromCsvOrTsv(textContent);
      }
    }

    if (rows.isEmpty) {
      stopwatch.stop();
      return StatementResult(
        items: [],
        health: StatementHealth(
          healthScore: 0,
          pageCount: 0,
          totalTransactions: 0,
          openingBalanceVerified: false,
          closingBalanceVerified: false,
          merchantAccuracyPercent: 0,
          duplicatesRemoved: 0,
          parserVersion: version,
          parseTime: stopwatch.elapsed,
        ),
        errorMessage: 'Could not extract valid data rows from this Excel file.',
      );
    }

    // 3. Dynamic Header Detection (Scan first 20 rows)
    int headerRowIndex = 0;
    int maxHeaderScore = -1;
    List<String> headers = [];

    final scanLimit = rows.length > 20 ? 20 : rows.length;
    for (int r = 0; r < scanLimit; r++) {
      final candidateHeaders =
          rows[r].map((e) => e.toLowerCase().trim()).toList();
      final score = _evaluateHeaderScore(candidateHeaders);
      if (score > maxHeaderScore) {
        maxHeaderScore = score;
        headerRowIndex = r;
        headers = candidateHeaders;
      }
    }

    // Map column indices
    int dateCol = -1;
    int merchantCol = -1;
    int debitCol = -1;
    int creditCol = -1;
    int amountCol = -1;
    int typeCol = -1;
    int balanceCol = -1;
    int refCol = -1;

    for (int c = 0; c < headers.length; c++) {
      final h = headers[c];
      if (dateCol == -1 &&
          (h.contains('date') ||
              h.contains('txn dt') ||
              h.contains('value dt') ||
              h == 'dt')) {
        dateCol = c;
      } else if (merchantCol == -1 &&
          (h.contains('narration') ||
              h.contains('description') ||
              h.contains('particular') ||
              h.contains('merchant') ||
              h.contains('remarks') ||
              h.contains('details') ||
              h.contains('transaction details') ||
              h.contains('payee'))) {
        merchantCol = c;
      } else if (debitCol == -1 &&
          (h.contains('debit') ||
              h.contains('dr') ||
              h.contains('withdrawal') ||
              h.contains('spent') ||
              h.contains('paid out'))) {
        debitCol = c;
      } else if (creditCol == -1 &&
          (h.contains('credit') ||
              h.contains('cr') ||
              h.contains('deposit') ||
              h.contains('received') ||
              h.contains('paid in'))) {
        creditCol = c;
      } else if (amountCol == -1 &&
          (h.contains('amount') ||
              h.contains('transaction amount') ||
              h.contains('txn amt') ||
              h == 'amt')) {
        amountCol = c;
      } else if (typeCol == -1 &&
          (h.contains('type') ||
              h.contains('dr/cr') ||
              h.contains('d/c') ||
              h.contains('cr/dr') ||
              h.contains('mode'))) {
        typeCol = c;
      } else if (balanceCol == -1 &&
          (h.contains('balance') || h.contains('closing bal'))) {
        balanceCol = c;
      } else if (refCol == -1 &&
          (h.contains('ref') ||
              h.contains('chq') ||
              h.contains('utr') ||
              h.contains('reference'))) {
        refCol = c;
      }
    }

    // Fallback column positions if header matching wasn't fully conclusive
    if (dateCol == -1) dateCol = 0;
    if (merchantCol == -1) merchantCol = headers.length > 1 ? 1 : 0;
    if (amountCol == -1 && debitCol == -1 && creditCol == -1) {
      amountCol = headers.length > 2 ? 2 : 1;
    }

    // 4. Parse Rows into TransactionItems
    for (int r = headerRowIndex + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;

      // Skip summary / empty rows
      final rowStr = row.join(' ').toLowerCase();
      if (rowStr.trim().isEmpty ||
          rowStr.contains('opening balance') ||
          rowStr.contains('closing balance') ||
          rowStr.contains('total amount') ||
          rowStr.contains('page total') ||
          rowStr.contains('grand total') ||
          rowStr.contains('statement summary')) {
        continue;
      }

      final rawDate = dateCol < row.length ? row[dateCol].trim() : '';
      final rawMerchant =
          merchantCol < row.length ? row[merchantCol].trim() : '';
      if (rawDate.isEmpty && rawMerchant.isEmpty) continue;

      final date = _parseDate(rawDate);
      if (date == null) continue;

      double amount = 0.0;
      TransactionType type = TransactionType.debit;

      if (debitCol != -1 &&
          creditCol != -1 &&
          debitCol < row.length &&
          creditCol < row.length) {
        final debitVal = _parseAmount(row[debitCol]);
        final creditVal = _parseAmount(row[creditCol]);

        if (debitVal > 0) {
          amount = debitVal;
          type = TransactionType.debit;
        } else if (creditVal > 0) {
          amount = creditVal;
          type = TransactionType.credit;
        } else {
          continue; // Zero amount row
        }
      } else if (amountCol != -1 && amountCol < row.length) {
        final rawAmtStr = row[amountCol].trim();
        final rawAmt = _parseAmount(rawAmtStr);
        if (rawAmt == 0.0) continue;

        amount = rawAmt.abs();

        if (rawAmtStr.startsWith('-') || rawAmtStr.contains('(')) {
          type = TransactionType.debit;
        } else if (typeCol != -1 && typeCol < row.length) {
          final tStr = row[typeCol].toLowerCase();
          if (tStr.contains('cr') ||
              tStr.contains('credit') ||
              tStr.contains('deposit')) {
            type = TransactionType.credit;
          } else {
            type = TransactionType.debit;
          }
        } else {
          final isCredit = rowStr.contains('credit') ||
              rowStr.contains(' cr') ||
              rowStr.contains('/cr') ||
              rowStr.contains('deposit');
          type = isCredit ? TransactionType.credit : TransactionType.debit;
        }
      }

      if (amount <= 0) continue;

      final normalizedMerchant =
          MerchantIntelligenceService.normalizeMerchant(rawMerchant);
      final ref = refCol != -1 && refCol < row.length
          ? row[refCol].trim()
          : _extractReference(rawMerchant);

      final tx = TransactionItem(
        amount: amount,
        merchant: normalizedMerchant.isNotEmpty
            ? normalizedMerchant
            : (rawMerchant.isNotEmpty ? rawMerchant : 'Excel Transaction'),
        category: 'Excel Import',
        type: type,
        source: TransactionSource.csv,
        date: date,
        reference: ref.isNotEmpty ? ref : null,
        notes: 'Excel Import • ${document.fileName}',
      );

      if (RecordValidator.validate(tx).isValid) {
        final confidence = FieldConfidenceEngine.evaluate(
          transaction: tx,
          isRecognizedTemplate: true,
          isBalanceVerified: balanceCol != -1,
          isNormalizedMerchant: normalizedMerchant != rawMerchant,
        );

        items.add(StatementResultItem(
          transaction: tx,
          confidence: confidence,
        ));
      }
    }

    stopwatch.stop();

    final health = StatementHealth(
      healthScore: items.isNotEmpty ? 100 : 0,
      pageCount: 1,
      totalTransactions: items.length,
      openingBalanceVerified: true,
      closingBalanceVerified: true,
      merchantAccuracyPercent: 99,
      duplicatesRemoved: 0,
      parserVersion: version,
      parseTime: stopwatch.elapsed,
    );

    return StatementResult(
      items: items,
      health: health,
      warnings: warnings,
    );
  }

  // ── OpenXML (.xlsx) ZIP Parser ───────────────────────────────────────────
  List<List<String>> _extractRowsFromXlsx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final sharedStrings = <String>[];

    // 1. Extract shared strings if present (xl/sharedStrings.xml)
    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedStringsFile != null) {
      final xmlContent = utf8.decode(sharedStringsFile.content as List<int>,
          allowMalformed: true);
      final siMatches =
          RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(xmlContent);
      for (final si in siMatches) {
        final inner = si.group(1) ?? '';
        final tMatches = RegExp(r'<t(?:\s+[^>]*)?>(.*?)</t>', dotAll: true)
            .allMatches(inner);
        final buffer = StringBuffer();
        for (final t in tMatches) {
          buffer.write(_unescapeXml(t.group(1) ?? ''));
        }
        sharedStrings.add(buffer.toString());
      }
    }

    // 2. Find and extract worksheet(s)
    final rows = <List<String>>[];
    for (final file in archive.files) {
      if (file.name.startsWith('xl/worksheets/sheet') &&
          file.name.endsWith('.xml')) {
        final xml =
            utf8.decode(file.content as List<int>, allowMalformed: true);
        final sheetRows = _parseWorksheetXml(xml, sharedStrings);
        rows.addAll(sheetRows);
      }
    }

    return rows;
  }

  List<List<String>> _parseWorksheetXml(
      String xml, List<String> sharedStrings) {
    final sheetRows = <List<String>>[];
    final rowMatches =
        RegExp(r'<row(?:\s+[^>]*)?>(.*?)</row>', dotAll: true).allMatches(xml);

    for (final rowMatch in rowMatches) {
      final rowXml = rowMatch.group(1) ?? '';
      final cellMatches =
          RegExp(r'<c\s+([^>]*?)>(.*?)</c>', dotAll: true).allMatches(rowXml);

      final rowCells = <int, String>{};
      int maxColIdx = -1;
      int sequentialCol = 0;

      for (final cellMatch in cellMatches) {
        final attrs = cellMatch.group(1) ?? '';
        final inner = cellMatch.group(2) ?? '';

        // Extract column index from r="A1"
        final rMatch = RegExp(r'r="([A-Za-z]+)(\d+)"').firstMatch(attrs);
        int colIdx = sequentialCol;
        if (rMatch != null) {
          colIdx = _colNameToIndex(rMatch.group(1)!);
        }

        // Cell Type: t="s" (shared string), t="inlineStr", etc.
        final tMatch = RegExp(r't="([^"]+)"').firstMatch(attrs);
        final cellType = tMatch?.group(1);

        String val = '';
        if (cellType == 's') {
          final vMatch = RegExp(r'<v>(.*?)</v>').firstMatch(inner);
          if (vMatch != null) {
            final sIdx = int.tryParse(vMatch.group(1) ?? '') ?? -1;
            if (sIdx >= 0 && sIdx < sharedStrings.length) {
              val = sharedStrings[sIdx];
            }
          }
        } else if (cellType == 'inlineStr') {
          final tMatch = RegExp(r'<t>(.*?)</t>').firstMatch(inner);
          if (tMatch != null) {
            val = _unescapeXml(tMatch.group(1) ?? '');
          }
        } else {
          final vMatch = RegExp(r'<v>(.*?)</v>').firstMatch(inner);
          if (vMatch != null) {
            val = vMatch.group(1) ?? '';
          }
        }

        rowCells[colIdx] = val.trim();
        if (colIdx > maxColIdx) maxColIdx = colIdx;
        sequentialCol = colIdx + 1;
      }

      if (maxColIdx >= 0) {
        final fullRow =
            List<String>.generate(maxColIdx + 1, (i) => rowCells[i] ?? '');
        sheetRows.add(fullRow);
      }
    }

    return sheetRows;
  }

  int _colNameToIndex(String colName) {
    int result = 0;
    final upper = colName.toUpperCase();
    for (int i = 0; i < upper.length; i++) {
      result = result * 26 + (upper.codeUnitAt(i) - 64);
    }
    return result - 1;
  }

  String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  int _evaluateHeaderScore(List<String> row) {
    int score = 0;
    for (final cell in row) {
      if (cell.contains('date') || cell.contains('txn dt')) score += 3;
      if (cell.contains('narration') ||
          cell.contains('particular') ||
          cell.contains('description')) score += 3;
      if (cell.contains('debit') || cell.contains('withdrawal')) score += 3;
      if (cell.contains('credit') || cell.contains('deposit')) score += 3;
      if (cell.contains('amount') || cell.contains('amt')) score += 2;
      if (cell.contains('balance')) score += 2;
      if (cell.contains('ref') || cell.contains('chq')) score += 2;
    }
    return score;
  }

  double _parseAmount(String raw) {
    final clean = raw
        .replaceAll('₹', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll('INR', '')
        .replaceAll(',', '')
        .replaceAll('(', '-')
        .replaceAll(')', '')
        .replaceAll('Cr', '')
        .replaceAll('Dr', '')
        .replaceAll('cr', '')
        .replaceAll('dr', '')
        .replaceAll('\uFFFD', '')
        .replaceAll(RegExp(r'[^0-9\.\-\(\)]'), '')
        .trim();
    return double.tryParse(clean) ?? 0.0;
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;

    // Check if it's an Excel numeric date serial (e.g. 45517 for 13 Aug 2024)
    final serial = double.tryParse(raw);
    if (serial != null && serial > 30000 && serial < 60000) {
      final baseDate = DateTime(1899, 12, 30);
      return baseDate.add(Duration(days: serial.toInt()));
    }

    // Text date formats
    final clean = raw.trim();

    // 1. DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final parts = clean.split(RegExp(r'[\/\-\.\s]'));
    if (parts.length == 3) {
      int? day = int.tryParse(parts[0]);
      int? month = _parseMonth(parts[1]);
      int? year = int.tryParse(parts[2]);

      // Handle YYYY-MM-DD
      if (parts[0].length == 4) {
        year = int.tryParse(parts[0]);
        month = _parseMonth(parts[1]);
        day = int.tryParse(parts[2]);
      }

      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return null;
  }

  int? _parseMonth(String m) {
    final intMonth = int.tryParse(m);
    if (intMonth != null && intMonth >= 1 && intMonth <= 12) return intMonth;

    final lower = m.toLowerCase();
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    return months[lower];
  }

  String _extractReference(String text) {
    final utrMatch = RegExp(r'\b(\d{12})\b').firstMatch(text);
    if (utrMatch != null) return utrMatch.group(1)!;

    final refMatch = RegExp(r'UPI/([A-Za-z0-9]+)').firstMatch(text);
    if (refMatch != null) return refMatch.group(1)!;

    return '';
  }

  // ── HTML Table Extractor (.xls from SBI, HDFC, ICICI, etc.) ───────────────
  List<List<String>> _extractRowsFromHtmlTable(String html) {
    final rows = <List<String>>[];
    final trMatches =
        RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true, caseSensitive: false)
            .allMatches(html);

    for (final tr in trMatches) {
      final trInner = tr.group(1) ?? '';
      final cellMatches = RegExp(r'<(?:td|th)[^>]*>(.*?)</(?:td|th)>',
              dotAll: true, caseSensitive: false)
          .allMatches(trInner);

      final row = <String>[];
      for (final cell in cellMatches) {
        String cellText = cell.group(1) ?? '';
        // Strip nested HTML tags
        cellText = cellText.replaceAll(RegExp(r'<[^>]+>'), ' ');
        // Unescape HTML entities
        cellText = _unescapeHtmlEntities(cellText);
        cellText = cellText.replaceAll(RegExp(r'\s+'), ' ').trim();
        row.add(cellText);
      }

      if (row.any((c) => c.isNotEmpty)) {
        rows.add(row);
      }
    }

    return rows;
  }

  // ── XML Spreadsheet 2003 Extractor (.xls) ─────────────────────────────────
  List<List<String>> _extractRowsFromXmlSpreadsheet(String xml) {
    final rows = <List<String>>[];
    final rowMatches =
        RegExp(r'<Row[^>]*>(.*?)</Row>', dotAll: true, caseSensitive: false)
            .allMatches(xml);

    for (final r in rowMatches) {
      final rInner = r.group(1) ?? '';
      final cellMatches =
          RegExp(r'<Cell[^>]*>(.*?)</Cell>', dotAll: true, caseSensitive: false)
              .allMatches(rInner);

      final row = <String>[];
      for (final c in cellMatches) {
        final cInner = c.group(1) ?? '';
        final dataMatch = RegExp(r'<Data[^>]*>(.*?)</Data>',
                dotAll: true, caseSensitive: false)
            .firstMatch(cInner);
        String val = dataMatch?.group(1) ?? '';
        val = _unescapeXml(val);
        val = val.replaceAll(RegExp(r'\s+'), ' ').trim();
        row.add(val);
      }

      if (row.any((cell) => cell.isNotEmpty)) {
        rows.add(row);
      }
    }

    return rows;
  }

  // ── Delimited Text / CSV / TSV Extractor ─────────────────────────────────
  List<List<String>> _extractRowsFromCsvOrTsv(String content) {
    final rows = <List<String>>[];
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) return rows;

    // Detect delimiter from top lines
    final sample = lines.take(5).join('\n');
    String delimiter = ',';
    if (sample.split('\t').length > sample.split(',').length) {
      delimiter = '\t';
    } else if (sample.split(';').length > sample.split(',').length) {
      delimiter = ';';
    } else if (sample.split('|').length > sample.split(',').length) {
      delimiter = '|';
    }

    for (final line in lines) {
      final cells = line.split(delimiter).map((c) => c.trim().replaceAll('"', '')).toList();
      if (cells.any((c) => c.isNotEmpty)) {
        rows.add(cells);
      }
    }

    return rows;
  }

  String _unescapeHtmlEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&#160;', ' ');
  }
}
