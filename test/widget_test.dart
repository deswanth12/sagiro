import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/providers/subscription_provider.dart';
import 'package:sagiro/providers/authentication_provider.dart';
import 'package:sagiro/billing/billing_provider.dart';
import 'package:sagiro/views/dashboard_page.dart';
import 'package:sagiro/views/budget_page.dart';
import 'package:sagiro/views/insights_page.dart';
import 'package:sagiro/views/main_navigation_screen.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Widget Tests — UI Component Rendering', () {
    testWidgets('DashboardPage renders dashboard widget cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const DashboardPage()));
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('BudgetPage renders velocity forecast radar',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const BudgetPage()));
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Budget Engine'), findsOneWidget);
      expect(find.text('No Monthly Budget Set'), findsOneWidget);
      expect(find.text('Category Spend Breakdown'), findsOneWidget);
    });

    testWidgets('InsightsPage renders financial journey empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const InsightsPage()));
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Your financial story starts today.'), findsOneWidget);
    });

    testWidgets(
        'MainNavigationScreen displays navigation items including Guide tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BudgetProvider()),
            ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
            ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
            ChangeNotifierProvider(create: (_) => BillingProvider()),
          ],
          child: const MaterialApp(home: MainNavigationScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Money Brain'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Vault'), findsOneWidget);
    });
  });
}
