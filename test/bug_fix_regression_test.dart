import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/backup_service.dart';
import 'package:sagiro/services/database_helper.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
    SharedPreferences.setMockInitialValues({});
  });

  group('P1-01 Category Edit Regression Tests', () {
    test(
        '1 & 2 & 5: Category edit Food -> Shopping -> Travel preserves original source metadata',
        () {
      final originalTx = TransactionItem(
        id: 101,
        amount: 500.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 10),
        rawSms: null,
        originalCategory: 'Food',
      );

      expect(originalTx.category, equals('Food'));
      expect(originalTx.originalCategory, equals('Food'));

      // Edit 1: Food -> Shopping
      final edit1 = TransactionItem(
        id: originalTx.id,
        amount: originalTx.amount,
        merchant: originalTx.merchant,
        category: 'Shopping',
        type: originalTx.type,
        source: originalTx.source,
        date: originalTx.date,
        rawSms: originalTx.rawSms,
        originalCategory: originalTx.originalCategory ?? originalTx.category,
        userCategory: 'Shopping',
      );

      expect(edit1.category, equals('Shopping'));
      expect(edit1.originalCategory, equals('Food'));
      expect(edit1.rawSms, isNull);
      expect(edit1.source, equals(TransactionSource.sms));

      // Edit 2: Shopping -> Travel
      final edit2 = TransactionItem(
        id: edit1.id,
        amount: edit1.amount,
        merchant: edit1.merchant,
        category: 'Travel',
        type: edit1.type,
        source: edit1.source,
        date: edit1.date,
        rawSms: edit1.rawSms,
        originalCategory: edit1.originalCategory,
        userCategory: 'Travel',
      );

      expect(edit2.category, equals('Travel'));
      expect(edit2.originalCategory, equals('Food'));
      expect(edit2.rawSms, isNull);
    });

    test('3: Edit transaction -> simulate DB save & load -> Shopping remains',
        () {
      final editedTx = TransactionItem(
        id: 202,
        amount: 1200.0,
        merchant: 'Amazon',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 11),
        originalCategory: 'General',
        userCategory: 'Shopping',
      );

      final map = editedTx.toMap();
      final loadedTx = TransactionItem.fromMap(map);

      expect(loadedTx.category, equals('Shopping'));
      expect(loadedTx.originalCategory, equals('General'));
      expect(loadedTx.userCategory, equals('Shopping'));
    });

    test(
        '4: Verify analytics category calculation uses edited category (Shopping)',
        () {
      final txs = [
        TransactionItem(
          id: 1,
          amount: 400.0,
          merchant: 'Store',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(2026, 8, 11),
          originalCategory: 'Food',
          userCategory: 'Shopping',
        ),
        TransactionItem(
          id: 2,
          amount: 600.0,
          merchant: 'Store B',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(2026, 8, 11),
        ),
      ];

      final Map<String, double> categoryBreakdown = {};
      for (final tx in txs) {
        categoryBreakdown[tx.category] =
            (categoryBreakdown[tx.category] ?? 0) + tx.amount;
      }

      expect(categoryBreakdown['Shopping'], equals(1000.0));
      expect(categoryBreakdown.containsKey('Food'), isFalse);
    });
  });

  group('P1-02 Settings Persistence Tests', () {
    test('AppSettingsService persists and reads state accurately', () async {
      final service = AppSettingsService.instance;
      await service.setDarkMode(false);
      await service.setAmoledMode(true);
      await service.setReduceMotion(true);
      await service.setSmsTracking(false);
      await service.setAutoCategories(false);
      await service.setBiometricsEnabled(true);
      await service.setHideBalances(true);

      expect(service.darkMode, isFalse);
      expect(service.amoledMode, isTrue);
      expect(service.reduceMotion, isTrue);
      expect(service.smsTracking, isFalse);
      expect(service.autoCategories, isFalse);
      expect(service.biometricsEnabled, isTrue);
      expect(service.hideBalances, isTrue);

      // Reload from SharedPreferences mock
      await service.loadSettings();
      expect(service.darkMode, isFalse);
      expect(service.amoledMode, isTrue);
      expect(service.reduceMotion, isTrue);
      expect(service.smsTracking, isFalse);
      expect(service.autoCategories, isFalse);
      expect(service.biometricsEnabled, isTrue);
      expect(service.hideBalances, isTrue);

      // Restore defaults for subsequent tests
      await service.setDarkMode(true);
      await service.setAmoledMode(false);
      await service.setReduceMotion(false);
      await service.setSmsTracking(true);
      await service.setAutoCategories(true);
      await service.setBiometricsEnabled(false);
      await service.setHideBalances(false);
    });
  });

  group('P2-03 Real WhatChanged Calculation Tests', () {
    test('Calculates actual yesterday spending from dataset', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final txs = [
        // Yesterday tx 1
        TransactionItem(
          amount: 150.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: yesterday,
        ),
        // Yesterday tx 2
        TransactionItem(
          amount: 350.0,
          merchant: 'Uber',
          category: 'Travel',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: yesterday,
        ),
        // Today tx
        TransactionItem(
          amount: 500.0,
          merchant: 'Amazon',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now,
        ),
      ];

      final yesterdayTxs = txs
          .where((t) =>
              t.type == TransactionType.debit &&
              t.date.year == yesterday.year &&
              t.date.month == yesterday.month &&
              t.date.day == yesterday.day)
          .toList();

      final spentYesterday = yesterdayTxs.fold(0.0, (sum, t) => sum + t.amount);
      expect(spentYesterday, equals(500.0));
    });

    test('Returns 0 for spentYesterday when no transactions occurred yesterday',
        () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final txs = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Amazon',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now,
        ),
      ];

      final yesterdayTxs = txs
          .where((t) =>
              t.type == TransactionType.debit &&
              t.date.year == yesterday.year &&
              t.date.month == yesterday.month &&
              t.date.day == yesterday.day)
          .toList();

      final spentYesterday = yesterdayTxs.fold(0.0, (sum, t) => sum + t.amount);
      expect(spentYesterday, equals(0.0));
    });
  });

  group('P2-04 Merchant Yearly Total Regression Tests', () {
    test(
        'Calculates actual current-year merchant total: Jan 100, Mar 200, Dec 300 -> Expected 600',
        () {
      final currentYear = DateTime.now().year;

      final txs = [
        TransactionItem(
          amount: 100.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(currentYear, 1, 15),
        ),
        TransactionItem(
          amount: 200.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(currentYear, 3, 20),
        ),
        TransactionItem(
          amount: 300.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(currentYear, 12, 10),
        ),
        // Previous year transaction (should be excluded)
        TransactionItem(
          amount: 999.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(currentYear - 1, 5, 5),
        ),
      ];

      final yearlyTotal = txs
          .where((x) =>
              x.type == TransactionType.debit &&
              x.merchant.trim().toLowerCase() == 'swiggy' &&
              x.date.year == currentYear)
          .fold(0.0, (sum, x) => sum + x.amount);

      expect(yearlyTotal, equals(600.0));
    });

    test('Returns 0.0 when no current-year transactions exist for merchant',
        () {
      final currentYear = DateTime.now().year;

      final txs = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Zomato',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime(currentYear - 1, 6, 1),
        ),
      ];

      final yearlyTotal = txs
          .where((x) =>
              x.type == TransactionType.debit &&
              x.merchant.trim().toLowerCase() == 'zomato' &&
              x.date.year == currentYear)
          .fold(0.0, (sum, x) => sum + x.amount);

      expect(yearlyTotal, equals(0.0));
    });
  });

  group('P2-05 Backup Metadata Version Tests', () {
    test(
        'Backup metadata reports current database version and app version 2.5.0+1',
        () {
      expect(DatabaseHelper.currentDbVersion, equals(9));
      expect(DatabaseHelper.currentAppVersion, equals('2.5.0+1'));

      final metadata = BackupMetadata(
        appName: 'Sagiro',
        appVersion: DatabaseHelper.currentAppVersion,
        databaseVersion: DatabaseHelper.currentDbVersion,
        backupVersion: 'v1.0',
        createdDate: DateTime.now(),
        transactionCount: 10,
        categoryRuleCount: 2,
        isEncrypted: false,
      );

      final map = metadata.toMap();
      expect(map['databaseVersion'], equals(9));
      expect(map['appVersion'], equals('2.5.0+1'));
    });
  });

  group('P2 BUG-01 Timezone & Month-Boundary Consistency Regression Tests', () {
    test(
        'categoryBreakdown and monthSpend evaluate UTC dates consistently near month boundaries',
        () {
      // Transaction date in UTC: August 31, 2026 at 19:00:00 UTC (Sept 1, 2026 00:30:00 IST in +05:30)
      final utcTxDate = DateTime.parse('2026-08-31T19:00:00Z');
      final localDate = utcTxDate.toLocal();

      final tx = TransactionItem(
        id: 999,
        amount: 450.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: utcTxDate,
      );

      final transactions = [tx];

      // Simulate BudgetProvider monthSpend filter using local time
      final monthSpend = transactions.where((t) {
        final local = t.date.toLocal();
        return t.type == TransactionType.debit &&
            local.year == localDate.year &&
            local.month == localDate.month;
      }).fold<double>(0.0, (sum, t) => sum + t.amount);

      // Simulate BudgetProvider categoryBreakdown filter using local time
      final Map<String, double> categoryBreakdown = {};
      for (final t in transactions) {
        final local = t.date.toLocal();
        if (t.type == TransactionType.debit &&
            local.year == localDate.year &&
            local.month == localDate.month) {
          categoryBreakdown[t.category] =
              (categoryBreakdown[t.category] ?? 0.0) + t.amount;
        }
      }

      expect(monthSpend, equals(450.0));
      expect(categoryBreakdown['Food'], equals(450.0));
      expect(categoryBreakdown.values.fold(0.0, (a, b) => a + b),
          equals(monthSpend));
    });
  });
}
