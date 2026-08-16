import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/csv_importer.dart';
import 'package:sagiro/providers/budget_provider.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('CSV Importer 100% Source-to-Import Reconciliation Golden Tests', () {
    test(
        '1. 10-Row CSV Fixture: Reconciles 7 valid, 2 duplicates, 1 invalid with zero data loss',
        () async {
      final sb = StringBuffer();
      sb.writeln('Date,Description,Withdrawal,Deposit,Ref No');
      // 7 Valid transactions
      sb.writeln('01/08/2026,Swiggy Lunch,250,,TXN101');
      sb.writeln('02/08/2026,Amazon Shopping,1200,,TXN102');
      sb.writeln('03/08/2026,Salary Credit,,25000,TXN103');
      sb.writeln('04/08/2026,Uber Ride,180,,TXN104');
      sb.writeln('05/08/2026,Electricity Bill,1450,,TXN105');
      sb.writeln('06/08/2026,Zomato Dinner,350,,TXN106');
      sb.writeln('07/08/2026,Mobile Recharge,599,,TXN107');
      // 2 Duplicates (matching ref TXN101 and TXN102)
      sb.writeln('01/08/2026,Swiggy Lunch,250,,TXN101');
      sb.writeln('02/08/2026,Amazon Shopping,1200,,TXN102');
      // 1 Invalid row (unparseable date)
      sb.writeln('INVALID_DATE,Grocery,500,,TXN108');

      final result = CsvImporterService.parseCsv(
        sb.toString(),
        fileName: 'Fixture_10Rows.csv',
      );

      expect(result.totalSourceDataRows, equals(10));
      expect(result.validTransactionsCount, equals(7));
      expect(result.duplicateCount, equals(2));
      expect(result.invalidCount, equals(1));
      expect(result.reconciles, isTrue);

      // Verify every row status is explicitly accounted for
      expect(result.rowStatuses.length, equals(11)); // 1 header + 10 data rows
      expect(
          result.rowStatuses[1].reason, contains('Row 2: Valid transaction'));
      expect(
          result.rowStatuses[8].reason, contains('Already imported duplicate'));
      expect(result.rowStatuses[10].reason, contains('unparseable'));
    });

    test(
        '2. 50-Row CSV Fixture: Preserves multiple identical purchases on same date (Amazon ₹500)',
        () async {
      final sb = StringBuffer();
      sb.writeln('Date,Merchant,Amount,Type,Ref');

      // 45 Valid transactions (including two identical ₹500 Amazon purchases on 11 Aug with different ref IDs)
      for (int i = 1; i <= 43; i++) {
        sb.writeln('10/08/2026,Merchant $i,${i * 100},Debit,REF-$i');
      }
      sb.writeln('11/08/2026,Amazon Order 1,500,Debit,REF-AMZ-1');
      sb.writeln('11/08/2026,Amazon Order 2,500,Debit,REF-AMZ-2');

      // 3 Duplicates
      sb.writeln('10/08/2026,Merchant 1,100,Debit,REF-1');
      sb.writeln('10/08/2026,Merchant 2,200,Debit,REF-2');
      sb.writeln('10/08/2026,Merchant 3,300,Debit,REF-3');

      // 2 Invalid rows (zero amount)
      sb.writeln('12/08/2026,Zero Amount Txn,0,Debit,REF-ERR-1');
      sb.writeln('12/08/2026,Blank Amount Txn,,Debit,REF-ERR-2');

      final result = CsvImporterService.parseCsv(
        sb.toString(),
        fileName: 'Fixture_50Rows.csv',
      );

      expect(result.totalSourceDataRows, equals(50));
      expect(result.validTransactionsCount, equals(45));
      expect(result.duplicateCount, equals(3));
      expect(result.invalidCount, equals(2));
      expect(result.reconciles, isTrue);

      // Verify that BOTH Amazon ₹500 transactions survived!
      final amazonTxns = result.transactions
          .where((t) => t.merchant.contains('Amazon'))
          .toList();
      expect(amazonTxns.length, equals(2));
    });

    test(
        '3. GOLDEN TEST: 100 Valid Original Source Transactions -> 100% Imported with ZERO loss',
        () async {
      final sb = StringBuffer();
      sb.writeln('Date,Description,Withdrawal,Deposit,Reference');

      for (int i = 1; i <= 100; i++) {
        final day = (i % 28) + 1;
        final dayStr = day < 10 ? '0$day' : '$day';
        final isDebit = i % 4 != 0;
        final amt = i * 50;
        if (isDebit) {
          sb.writeln('$dayStr/08/2026,Merchant Txn #$i,$amt,,UTRN-$i');
        } else {
          sb.writeln('$dayStr/08/2026,Income Credit #$i,,$amt,UTRN-$i');
        }
      }

      final result = CsvImporterService.parseCsv(
        sb.toString(),
        fileName: 'Golden_100Rows.csv',
      );

      expect(result.totalSourceDataRows, equals(100));
      expect(result.validTransactionsCount, equals(100));
      expect(result.duplicateCount, equals(0));
      expect(result.invalidCount, equals(0));
      expect(result.needsReviewCount, equals(0));
      expect(result.reconciles, isTrue);

      // Assert ZERO missing rows
      expect(result.validTransactionsCount + result.skippedRows, equals(100));
    });

    test(
        '4. Atomic Batch Insertion into SQLite: 100% of validated transactions reach DB',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final sb = StringBuffer();
      sb.writeln('Date,Merchant,Amount,Type,Ref');
      for (int i = 1; i <= 25; i++) {
        sb.writeln('05/08/2026,Batch Txn #$i,${i * 15},Debit,BATCH-$i');
      }

      final parseResult = CsvImporterService.parseCsv(sb.toString());
      expect(parseResult.transactions.length, equals(25));

      final batchResult =
          await provider.addTransactionsBatch(parseResult.transactions);
      expect(batchResult.insertedCount, equals(25));
      expect(batchResult.failedCount, equals(0));
      expect(batchResult.errors.isEmpty, isTrue);
    });
  });
}
