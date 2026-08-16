import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/csv_importer.dart';
import 'package:sagiro/models/transaction.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Problem 7: CSV Importer Test Suite', () {
    test('1. Handles UTF-8 BOM encoding gracefully', () {
      const csvWithBom =
          '\uFEFFDate,Description,Amount\n13/08/2026,Swiggy,450.00\n';
      final res = CsvImporterService.parseCsv(csvWithBom);

      expect(res.transactions.length, equals(1));
      expect(res.transactions.first.merchant, equals('Swiggy'));
      expect(res.transactions.first.amount, equals(450.0));
    });

    test('2. Supports comma, semicolon, and tab delimiters', () {
      const semicolonCsv =
          'Date;Description;Amount\n13/08/2026;Zomato;550.00\n';
      final resSemi = CsvImporterService.parseCsv(semicolonCsv);
      expect(resSemi.transactions.length, equals(1));
      expect(resSemi.transactions.first.merchant, equals('Zomato'));

      const tabCsv = 'Date\tDescription\tAmount\n13/08/2026\tUber\t250.00\n';
      final resTab = CsvImporterService.parseCsv(tabCsv);
      expect(resTab.transactions.length, equals(1));
      expect(resTab.transactions.first.merchant, equals('Uber'));
    });

    test(
        '3. Parses various amount formats (symbols, negative, parentheses, separate Debit/Credit)',
        () {
      const csv = '''Date,Description,Debit,Credit,Amount
13/08/2026,Swiggy,450.00,,
13/08/2026,Salary,,85000.00,
13/08/2026,Amazon,,,"-₹1,234.56"
13/08/2026,Refund,,,Rs 500.00
13/08/2026,Gas,,,(350.00)
''';
      final res = CsvImporterService.parseCsv(csv);
      expect(res.transactions.length, equals(5));
      expect(res.transactions[0].amount, equals(450.0));
      expect(res.transactions[0].type, equals(TransactionType.debit));
      expect(res.transactions[1].amount, equals(85000.0));
      expect(res.transactions[1].type, equals(TransactionType.credit));
      expect(res.transactions[2].amount, equals(1234.56));
      expect(res.transactions[2].type, equals(TransactionType.debit));
      expect(res.transactions[3].amount, equals(500.0));
      expect(res.transactions[4].amount, equals(350.0));
      expect(res.transactions[4].type, equals(TransactionType.debit));
    });

    test(
        '4. Date format detection (dd/MM/yyyy, yyyy-MM-dd, MM/dd/yyyy, dd-MMM-yyyy)',
        () {
      const csv = '''Date,Description,Amount
13/08/2026,Item 1,100
2026-08-13,Item 2,200
08/13/2026,Item 3,300
13-Aug-2026,Item 4,400
''';
      final res = CsvImporterService.parseCsv(csv);
      expect(res.transactions.length, equals(4));
    });

    test(
        '5. Category Reconciliation (Swiggy->Food, Amazon->Shopping, Petrol->Fuel, unknown->General)',
        () {
      const csv = '''Date,Description,Amount
13/08/2026,Swiggy Order,350
13/08/2026,Amazon Shopping,1200
13/08/2026,HPCL Petrol Pump,500
13/08/2026,Unknown Store,250
''';
      final res = CsvImporterService.parseCsv(csv);
      expect(res.transactions[0].category, equals('Food'));
      expect(res.transactions[1].category, equals('Shopping'));
      expect(res.transactions[2].category, equals('Fuel'));
      expect(res.transactions[3].category, equals('General'));
    });

    test('6. Duplicate Handling (Same CSV twice & CSV + SMS interaction)', () {
      const csv = '''Date,Description,Amount,Ref No
13/08/2026,Swiggy,450.00,UTR99887766
''';
      final res1 = CsvImporterService.parseCsv(csv);
      expect(res1.transactions.length, equals(1));

      // Re-importing same CSV against first result
      final res2 = CsvImporterService.parseCsv(csv,
          existingTransactions: res1.transactions);
      expect(res2.transactions.length, equals(0));
      expect(res2.duplicates.length, equals(1));
    });

    test('7. Error Handling: Malformed row does NOT crash entire import', () {
      const csv = '''Date,Description,Amount
13/08/2026,Valid Item,450.00
INVALID_DATE_ROW,Bad Item,500.00
13/08/2026,Another Valid Item,250.00
''';
      final res = CsvImporterService.parseCsv(csv);
      expect(res.transactions.length, equals(2));
      expect(res.invalidCount, equals(1));
      expect(res.parseErrors.length, equals(1));
    });

    test('8. Large CSV Benchmarking (10, 100, 1000, 10000 rows)', () {
      const header = 'Date,Description,Amount,Ref No\n';

      final String csv10 = header +
          List.generate(10, (i) => '13/08/2026,Merchant $i,100.00,REF10_$i')
              .join('\n');
      final stopwatch10 = Stopwatch()..start();
      final res10 = CsvImporterService.parseCsv(csv10);
      stopwatch10.stop();
      expect(res10.transactions.length, equals(10));

      final String csv100 = header +
          List.generate(100, (i) => '13/08/2026,Merchant $i,100.00,REF100_$i')
              .join('\n');
      final stopwatch100 = Stopwatch()..start();
      final res100 = CsvImporterService.parseCsv(csv100);
      stopwatch100.stop();
      expect(res100.transactions.length, equals(100));

      final String csv1000 = header +
          List.generate(1000, (i) => '13/08/2026,Merchant $i,100.00,REF1000_$i')
              .join('\n');
      final stopwatch1000 = Stopwatch()..start();
      final res1000 = CsvImporterService.parseCsv(csv1000);
      stopwatch1000.stop();
      expect(res1000.transactions.length, equals(1000));

      final String csv10000 = header +
          List.generate(
                  10000, (i) => '13/08/2026,Merchant $i,100.00,REF10000_$i')
              .join('\n');
      final stopwatch10000 = Stopwatch()..start();
      final res10000 = CsvImporterService.parseCsv(csv10000);
      stopwatch10000.stop();
      expect(res10000.transactions.length, equals(10000));
      expect(stopwatch10000.elapsedMilliseconds, lessThan(60000));
    });
  });
}
