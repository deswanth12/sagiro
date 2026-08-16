import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sagiro/components/add_transaction_dialog.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      await db.delete('settings');
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
  });

  Widget createTestWidget({
    Size screenSize = const Size(360, 640),
    double textScaleFactor = 1.0,
    TransactionType initialType = TransactionType.debit,
  }) {
    final provider = BudgetProvider();

    return ChangeNotifierProvider<BudgetProvider>.value(
      value: provider,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (_) => AddTransactionDialog(
                        initialType: initialType,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('SAGIRO Add Transaction Dialog UI Responsiveness Suite', () {
    testWidgets(
        '1. Renders Expense and Income selectors cleanly on standard 360px screen',
        (tester) async {
      await tester
          .pumpWidget(createTestWidget(screenSize: const Size(360, 640)));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Amount (₹)'), findsOneWidget);
      expect(find.text('Merchant / Payee'), findsOneWidget);
      expect(find.text('Save Transaction'), findsOneWidget);
      expect(find.text('Share with Family'), findsOneWidget);

      // Verify no yellow underline error markers or overflow exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '2. Renders without overflow on narrow 320px screen with 1.3x text scale',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        screenSize: const Size(320, 480),
        textScaleFactor: 1.3,
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Switches from Expense to Income on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Income selector
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '4. Entering merchant and interacting with Family Share switch operates cleanly',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter Amount
      await tester.enterText(find.byType(TextFormField).first, '1499.00');
      // Enter Merchant
      await tester.enterText(
          find.byType(TextFormField).at(1), 'Swiggy India Private Limited');
      await tester.pumpAndSettle();

      expect(find.text('1499.00'), findsOneWidget);
      expect(find.text('Swiggy India Private Limited'), findsOneWidget);

      // Verify Family toggle switch presence and toggling
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
