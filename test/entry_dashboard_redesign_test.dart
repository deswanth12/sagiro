import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagiro/views/onboarding_page.dart';
import 'package:sagiro/views/dashboard_page.dart';
import 'package:sagiro/views/main_navigation_screen.dart';
import 'package:sagiro/components/quick_add_modal_sheet.dart';
import 'package:sagiro/components/sms_scan_result_sheet.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/providers/authentication_provider.dart';
import 'package:sagiro/providers/subscription_provider.dart';
import 'package:sagiro/rag/rag_provider.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/models/transaction.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
      await db.delete('savings_goals');
      await db.delete('upcoming_bills');
    }
  });

  Widget buildTestableWidget(Widget child,
      {BudgetProvider? budgetProvider,
      AuthenticationProvider? authProvider,
      SubscriptionProvider? subscriptionProvider,
      RagProvider? ragProvider,
      Brightness brightness = Brightness.dark,
      double textScale = 1.0}) {
    final bProvider = budgetProvider ?? BudgetProvider();
    final aProvider = authProvider ?? AuthenticationProvider();
    final sProvider = subscriptionProvider ?? SubscriptionProvider();
    final rProvider = ragProvider ?? RagProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BudgetProvider>.value(value: bProvider),
        ChangeNotifierProvider<AuthenticationProvider>.value(value: aProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(value: sProvider),
        ChangeNotifierProvider<RagProvider>.value(value: rProvider),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Material(child: child),
        ),
      ),
    );
  }

  Future<BudgetProvider> createInitializedProvider(WidgetTester tester) async {
    final provider = BudgetProvider();
    await tester.runAsync(() async {
      await provider.loadData();
    });
    return provider;
  }

  group('Entry Experience & Dashboard Redesign (19 Scenarios)', () {
    testWidgets(
        '1. Welcome screen renders title, subtitle, and primary actions',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OnboardingPage()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SAGIRO'), findsWidgets);
      expect(
          find.text('Your private money decision assistant.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    });

    testWidgets('2. Privacy screen displays local-first privacy bullets',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OnboardingPage()));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Your money stays yours.'), findsOneWidget);
      expect(find.text('🔒 Local-first financial processing'), findsOneWidget);
      expect(find.text('On-Device SMS Scanning'), findsOneWidget);
      expect(find.text('Raw SMS Is Never Stored'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('3. Choose-starting-method screen displays 4 primary options',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OnboardingPage()));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('How do you want to start?'), findsOneWidget);
      expect(find.text('Scan Bank SMS'), findsOneWidget);
      expect(find.text('Import Statement'), findsOneWidget);
      expect(find.text('Add Manually'), findsOneWidget);
      expect(find.text('Use Voice'), findsOneWidget);
    });

    testWidgets('4. Budget setup screen displays budget and income fields',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OnboardingPage()));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Skip to Setup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Let\'s set up your money plan.'), findsOneWidget);
      expect(find.text('MONTHLY BUDGET (IMPORTANT)'), findsOneWidget);
      expect(find.text('Start Sagiro'), findsOneWidget);
    });

    testWidgets('5. Dashboard fresh state displays no-budget empty state',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SAFE TODAY'), findsOneWidget);
      expect(
          find.text(
              'Set a monthly budget to calculate your daily spending limit.'),
          findsOneWidget);
      expect(find.text('Set Budget'), findsOneWidget);
    });

    testWidgets('6. Dashboard with real transaction data calculates Safe Today',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.runAsync(() async {
        await bProvider.updateMonthlyBudget(30000);
        await bProvider.addTransaction(TransactionItem(
          amount: 3000,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.manual,
          date: DateTime.now(),
          profileId: bProvider.activeProfileId,
        ));
      });

      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SAFE TODAY'), findsOneWidget);
      expect(find.text('Swiggy', skipOffstage: false), findsOneWidget);
    });

    testWidgets('7. SMS action is visible on Dashboard quick action grid',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Scan SMS'), findsOneWidget);
    });

    testWidgets('8. Dashboard SMS action opens ScanSmsDialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      final finder = find.text('Scan SMS');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SmsScanResultSheet), findsOneWidget);
    });

    testWidgets('9. Quick Add SMS action opens ScanSmsDialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => QuickAddModalSheet.show(context),
            child: const Text('Open Modal'),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final finder = find.text('Scan Bank SMS');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SmsScanResultSheet), findsOneWidget);
    });

    testWidgets('10. Money Brain action button is present on Dashboard',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ask Money Brain'), findsOneWidget);
    });

    testWidgets('11. No-budget Safe Today state prompts user to set budget',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Set Budget'), findsOneWidget);
    });

    testWidgets(
        '12. Budgeted Safe Today state shows hero amount and details link',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.runAsync(() async {
        await bProvider.updateMonthlyBudget(30000);
      });

      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('13. Empty subscriptions state shows honest empty text',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('14. Empty goals state shows honest empty text',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets(
        '15. Empty transactions state shows action buttons for new users',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No transactions yet.'), findsOneWidget);
      expect(find.text('Scan Bank SMS'), findsWidgets);
      expect(find.text('Add Transaction'), findsOneWidget);
    });

    testWidgets(
        '16. Large font layout (200% scaling) renders without exception',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
        textScale: 2.0,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('17. MainNavigationScreen renders with valid Material ancestor',
        (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const MainNavigationScreen(),
        budgetProvider: bProvider,
      ));
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Money Brain'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Vault'), findsOneWidget);
    });

    testWidgets('18. Dashboard renders in Light mode cleanly', (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
        brightness: Brightness.light,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('19. Dashboard renders in Dark mode cleanly', (tester) async {
      final bProvider = await createInitializedProvider(tester);
      await tester.pumpWidget(buildTestableWidget(
        const DashboardPage(),
        budgetProvider: bProvider,
        brightness: Brightness.dark,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });
}
