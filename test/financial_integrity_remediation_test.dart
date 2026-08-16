import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/models/upcoming_bill.dart';
import 'package:sagiro/services/weekly_review_service.dart';
import 'package:sagiro/services/ask_your_money_engine.dart';
import 'package:sagiro/services/storage_info_service.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'test_helper.dart';

void main() {
  setupTestSqflite();

  group('Financial Integrity & Remediation Tests', () {
    test('1. StorageInfoService formatBytes handles edge cases and scale', () {
      expect(StorageInfoService.formatBytes(-1), equals('Storage unavailable'));
      expect(StorageInfoService.formatBytes(0), equals('0 B'));
      expect(StorageInfoService.formatBytes(512), equals('512 B'));
      expect(StorageInfoService.formatBytes(1024), equals('1.0 KB'));
      expect(StorageInfoService.formatBytes(1468006), equals('1.4 MB'));
      expect(StorageInfoService.formatBytes(1073741824), equals('1.0 GB'));
    });

    test(
        '2. WeeklyReviewService returns honest empty state when history < 14 days',
        () {
      final now = DateTime.now();
      final txs = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now.subtract(const Duration(days: 2)),
        ),
      ];

      final report = WeeklyReviewService.generateWeeklyReview(
        txs,
        upcomingBills: [],
        monthlyBudget: 30000.0,
        safeTodayLimit: 1000.0,
      );

      expect(
          report.gentleRecommendation, equals('Not enough spending data yet'));
      expect(report.nextWeekOutlook, equals('No upcoming bills'));
    });

    test(
        '3. WeeklyReviewService calculates 7-day vs previous 7-day comparison when history >= 14 days',
        () {
      final now = DateTime.now();
      final txs = [
        // Current 7 days (t - 2)
        TransactionItem(
          amount: 1000.0,
          merchant: 'Zomato',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now.subtract(const Duration(days: 2)),
        ),
        // Previous 7-day baseline (t - 10)
        TransactionItem(
          amount: 2000.0,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now.subtract(const Duration(days: 10)),
        ),
      ];

      final bill = UpcomingBill(
        id: 'bill-1',
        title: 'Electricity Bill',
        amount: 1500.0,
        dueDate: now.add(const Duration(days: 3)),
        providerEmoji: '⚡',
        category: 'Utilities',
      );

      final report = WeeklyReviewService.generateWeeklyReview(
        txs,
        upcomingBills: [bill],
        monthlyBudget: 30000.0,
        safeTodayLimit: 1000.0,
      );

      expect(
          report.gentleRecommendation, contains('Food spend decreased by 50%'));
      expect(report.nextWeekOutlook,
          contains('Upcoming fixed bills: Electricity Bill (₹1500)'));
    });

    test(
        '4. SpendingAnalyzer.generateTodayAdvice enforces 14-day history minimum',
        () {
      expect(SpendingAnalyzer.generateTodayAdvice([]),
          equals('Not enough transaction history yet.'));

      final now = DateTime.now();
      final recentOnly = [
        TransactionItem(
          amount: 300.0,
          merchant: 'Uber',
          category: 'Travel',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now.subtract(const Duration(days: 3)),
        ),
      ];
      expect(SpendingAnalyzer.generateTodayAdvice(recentOnly),
          equals('Not enough transaction history yet.'));

      final fourteenDayHistory = [
        TransactionItem(
          amount: 500.0,
          merchant: 'Uber',
          category: 'Travel',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now.subtract(const Duration(days: 2)),
        ),
        TransactionItem(
          amount: 1000.0,
          merchant: 'Uber',
          category: 'Travel',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now.subtract(const Duration(days: 10)),
        ),
        TransactionItem(
          amount: 100.0,
          merchant: 'Store',
          category: 'General',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: now.subtract(const Duration(days: 14)),
        ),
      ];
      expect(SpendingAnalyzer.generateTodayAdvice(fourteenDayHistory),
          contains('50% less on Travel'));
    });

    test(
        '5. BudgetProvider calculates Safe Today deterministically and updates on mutations',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.hasBudget, isFalse);
      expect(provider.dailySafeSpendingLimit, equals(0.0));

      await provider.updateMonthlyBudget(30000.0);
      expect(provider.hasBudget, isTrue);
      expect(provider.dailySafeSpendingLimit, greaterThan(0.0));
    });
  });
}
