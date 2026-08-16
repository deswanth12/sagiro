import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/components/financial_calendar_widget.dart';
import 'package:sagiro/models/upcoming_bill.dart';
import 'package:sagiro/models/transaction.dart';

void main() {
  group('FinancialCalendarWidget — Zero Fabricated Events Regression Tests',
      () {
    testWidgets(
        '1. New user with no data displays 0 Events and honest empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [],
              transactions: [],
            ),
          ),
        ),
      );

      expect(find.text('0 Events'), findsOneWidget);
      expect(find.text('No financial events yet'), findsOneWidget);
      expect(find.textContaining('Add a transaction or recurring expense'),
          findsOneWidget);

      // Verify ZERO fabricated events exist
      expect(find.text('₹85,000'), findsNothing);
      expect(find.text('₹12,000'), findsNothing);
      expect(find.text('₹4,500'), findsNothing);
      expect(find.text('₹1,200'), findsNothing);
      expect(find.text('4 Events'), findsNothing);
    });

    testWidgets('2. Add salary transaction → salary event appears dynamically',
        (WidgetTester tester) async {
      final salaryTx = TransactionItem(
        id: 101,
        merchant: 'ACME Corp Salary',
        amount: 85000,
        date: DateTime.now(),
        category: 'Salary',
        type: TransactionType.credit,
        source: TransactionSource.manual,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 85000,
              monthSpend: 0,
              upcomingBills: const [],
              transactions: [salaryTx],
            ),
          ),
        ),
      );

      expect(find.text('1 Event'), findsOneWidget);
      expect(find.text('🟢 ACME Corp Salary'), findsOneWidget);
      expect(find.text('₹85,000'), findsOneWidget);
    });

    testWidgets('3. Add recurring rent → rent event appears dynamically',
        (WidgetTester tester) async {
      final rentBill = UpcomingBill(
        id: 'rent_1',
        title: 'House Rent',
        amount: 15000,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        providerEmoji: '🏠',
        category: 'Rent',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [rentBill],
              transactions: const [],
            ),
          ),
        ),
      );

      expect(find.text('1 Event'), findsOneWidget);
      expect(find.text('🏠 House Rent'), findsOneWidget);
      expect(find.text('₹15,000'), findsOneWidget);
    });

    testWidgets('4. Add EMI → EMI event appears dynamically',
        (WidgetTester tester) async {
      final emiBill = UpcomingBill(
        id: 'emi_1',
        title: 'Car Loan EMI',
        amount: 7500,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        providerEmoji: '💳',
        category: 'EMI',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [emiBill],
              transactions: const [],
            ),
          ),
        ),
      );

      expect(find.text('1 Event'), findsOneWidget);
      expect(find.text('💳 Car Loan EMI'), findsOneWidget);
      expect(find.text('₹7,500'), findsOneWidget);
    });

    testWidgets('5. Add utility bill → utility event appears dynamically',
        (WidgetTester tester) async {
      final utilBill = UpcomingBill(
        id: 'util_1',
        title: 'Electricity Bill',
        amount: 2200,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        providerEmoji: '⚡',
        category: 'Utilities',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [utilBill],
              transactions: const [],
            ),
          ),
        ),
      );

      expect(find.text('1 Event'), findsOneWidget);
      expect(find.text('⚡ Electricity Bill'), findsOneWidget);
      expect(find.text('₹2,200'), findsOneWidget);
    });

    testWidgets('6. Delete recurring expense → event disappears',
        (WidgetTester tester) async {
      final rentBill = UpcomingBill(
        id: 'rent_1',
        title: 'House Rent',
        amount: 15000,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        providerEmoji: '🏠',
        category: 'Rent',
      );

      // Initial state with bill
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [rentBill],
              transactions: const [],
            ),
          ),
        ),
      );
      expect(find.text('1 Event'), findsOneWidget);

      // State after deleting bill
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [],
              transactions: [],
            ),
          ),
        ),
      );
      expect(find.text('0 Events'), findsOneWidget);
      expect(find.text('🏠 House Rent'), findsNothing);
    });

    testWidgets('7. Edit recurring expense → event updates',
        (WidgetTester tester) async {
      final initialBill = UpcomingBill(
        id: 'rent_1',
        title: 'House Rent',
        amount: 15000,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        providerEmoji: '🏠',
        category: 'Rent',
      );

      final editedBill = UpcomingBill(
        id: 'rent_1',
        title: 'Apartment Rent',
        amount: 18000,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        providerEmoji: '🏠',
        category: 'Rent',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [initialBill],
              transactions: const [],
            ),
          ),
        ),
      );
      expect(find.text('🏠 House Rent'), findsOneWidget);
      expect(find.text('₹15,000'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [editedBill],
              transactions: const [],
            ),
          ),
        ),
      );
      expect(find.text('🏠 Apartment Rent'), findsOneWidget);
      expect(find.text('₹18,000'), findsOneWidget);
      expect(find.text('🏠 House Rent'), findsNothing);
    });

    testWidgets('8. Restart app / Persistence simulation → real events persist',
        (WidgetTester tester) async {
      final persistentBill = UpcomingBill(
        id: 'persistent_1',
        title: 'WiFi Subscription',
        amount: 999,
        dueDate: DateTime.now().add(const Duration(days: 12)),
        providerEmoji: '🌐',
        category: 'Subscriptions',
      );

      // App launch 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [persistentBill],
              transactions: const [],
            ),
          ),
        ),
      );
      expect(find.text('1 Event'), findsOneWidget);

      // App restart / re-build from loaded database state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 50000,
              monthSpend: 0,
              upcomingBills: [persistentBill],
              transactions: const [],
            ),
          ),
        ),
      );
      expect(find.text('1 Event'), findsOneWidget);
      expect(find.text('🌐 WiFi Subscription'), findsOneWidget);
    });

    testWidgets('9. Fresh install verification → zero fabricated values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinancialCalendarWidget(
              monthlyBudget: 0,
              monthSpend: 0,
              upcomingBills: [],
              transactions: [],
            ),
          ),
        ),
      );

      expect(find.text('0 Events'), findsOneWidget);
      expect(find.text('Salary Credited'), findsNothing);
      expect(find.text('Rent Payment'), findsNothing);
      expect(find.text('EMI Deduction'), findsNothing);
      expect(find.text('Utility Bills'), findsNothing);
      expect(find.text('₹85,000'), findsNothing);
      expect(find.text('₹12,000'), findsNothing);
      expect(find.text('₹4,500'), findsNothing);
      expect(find.text('₹1,200'), findsNothing);
    });
  });
}
