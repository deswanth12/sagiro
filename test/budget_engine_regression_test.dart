import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/views/budget_page.dart';
import 'package:sagiro/views/subscriptions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helper.dart';

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
      await db.delete('savings_goals');
      await db.delete('upcoming_bills');
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
    await AppSettingsService.instance.loadSettings();
  });

  Widget buildTestApp(Widget child) {
    return ChangeNotifierProvider<BudgetProvider>(
      create: (_) => BudgetProvider(),
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Budget Engine & Subscription Detector Regression Tests', () {
    test('1. Fresh BudgetProvider has no fake ₹25,000 target', () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.hasBudget, isFalse);
      expect(provider.monthlyBudget, equals(0.0));
    });

    test(
        '2. BudgetProvider with no budget shows hasBudget=false and safeToday=0',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.hasBudget, isFalse);
      expect(provider.dailySafeSpendingLimit, equals(0.0));
      expect(provider.safeTodaySubtitle, contains('Set a monthly budget'));
    });

    test(
        '3. BudgetProvider with user-entered ₹25,000 budget correctly stores it',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.updateMonthlyBudget(25000.0);
      expect(provider.hasBudget, isTrue);
      expect(provider.monthlyBudget, equals(25000.0));
    });

    test('4. Subscription Detector with zero subscriptions displays zero',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.activeSubscriptions.isEmpty, isTrue);
      expect(provider.totalMonthlySubscriptionCost, equals(0.0));
    });

    test('5. No fake subscription records are created on fresh install',
        () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);
      // Subscriptions are derived from transactions — no separate table with seed data
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.transactions.isEmpty, isTrue);
      expect(provider.activeSubscriptions.isEmpty, isTrue);
    });

    testWidgets('6. BudgetPage renders without Material ancestor errors',
        (tester) async {
      await tester.pumpWidget(buildTestApp(const BudgetPage()));
      await tester.pumpAndSettle();

      // No Material ancestor errors should be thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '7. BudgetPage empty state shows "No Monthly Budget Set", not ₹25,000',
        (tester) async {
      await tester.pumpWidget(buildTestApp(const BudgetPage()));
      await tester.pumpAndSettle();

      expect(find.text('No Monthly Budget Set'), findsOneWidget);
      expect(find.textContaining('₹25,000'), findsNothing);
      expect(find.textContaining('₹25000'), findsNothing);
    });

    testWidgets(
        '8. SubscriptionsPage empty state shows correct description text',
        (tester) async {
      await tester.pumpWidget(buildTestApp(const SubscriptionsPage()));
      await tester.pumpAndSettle();

      expect(find.text('No recurring subscriptions detected yet.'),
          findsOneWidget);
      expect(
          find.textContaining('Subscriptions will appear here automatically'),
          findsOneWidget);
      // Ensure no fake Netflix/Spotify listed as detected subscriptions
      expect(find.textContaining('Netflix'), findsNothing);
      expect(find.textContaining('Spotify'), findsNothing);
    });

    test(
        '9. BudgetProvider with ₹25,000 user budget correctly calculates target',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      await provider.updateMonthlyBudget(25000.0);

      expect(provider.hasBudget, isTrue);
      expect(provider.monthlyBudget, equals(25000.0));
      expect(provider.budgetForecast.monthlyBudget, equals(25000.0));
    });

    test(
        '10. BudgetPage source has no hardcoded TextDecoration.underline on labels',
        () async {
      // Static source-level check: budget_page.dart must not contain
      // 'TextDecoration.underline' since no label in that file is a hyperlink.
      final source = await File('lib/views/budget_page.dart').readAsString();
      expect(
        source.contains('TextDecoration.underline'),
        isFalse,
        reason:
            'budget_page.dart must not apply underline decoration to normal labels.',
      );
    });
  });
}
