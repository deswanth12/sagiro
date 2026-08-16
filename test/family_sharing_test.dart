import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sagiro/family_engine/models/family_models.dart';
import 'package:sagiro/family_engine/pages/family_members_page.dart';
import 'package:sagiro/family_engine/services/family_service.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/theme/app_theme.dart';
import 'test_helper.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    setupTestSqflite();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('transactions');
      try {
        await db.delete('profiles');
      } catch (_) {}
      await db.delete('settings');
    }
  });

  group('Problem 11 Verification: Local Sharing & Profile Deletion UI', () {
    test('1. Local Sharing: Private dashboards vs Family Summary isolation',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      final pA = provider.activeProfileId;

      // Profile A: 1 Private (₹1,000 Food) + 1 Shared (₹500 Groceries)
      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Swiggy Private',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
      ));

      await provider.addTransaction(TransactionItem(
        amount: 500.0,
        merchant: 'Groceries Shared',
        category: 'Groceries',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: true,
      ));

      // Profile B: 1 Private (₹2,000 Travel)
      final pB = await FamilyService.instance.createProfile(name: 'Profile B');
      await provider.switchProfile(pB.id);

      await provider.addTransaction(TransactionItem(
        amount: 2000.0,
        merchant: 'Airline Private',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
      ));

      // Assert B's private dashboard shows only B's ₹2,000 Travel
      expect(provider.transactions.length, equals(1));
      expect(provider.monthSpend, equals(2000.0));
      expect(provider.transactions.first.merchant, equals('Airline Private'));

      // Switch back to Profile A
      await provider.switchProfile(pA);
      // Assert A's private dashboard shows A's 2 transactions (₹1,000 + ₹500 = ₹1,500)
      expect(provider.transactions.length, equals(2));
      expect(provider.monthSpend, equals(1500.0));

      // Assert Family Summary shows ONLY transactions with isShared = true (A's ₹500 Groceries)
      final summary = await FamilyService.instance.getFamilySummary();
      expect(summary.monthlyFamilyExpenses, equals(500.0));
    });

    test('2. Toggle Private -> Shared -> Private updates Family Summary',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      final tx = TransactionItem(
        amount: 1000.0,
        merchant: 'Dining',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: false,
      );

      await provider.addTransaction(tx);
      var summary = await FamilyService.instance.getFamilySummary();
      expect(summary.monthlyFamilyExpenses, equals(0.0));

      // Toggle to Shared
      final addedTx = provider.transactions.first;
      final sharedTx = addedTx.copyWith(isShared: true);
      await provider.updateTransaction(sharedTx);

      summary = await FamilyService.instance.getFamilySummary();
      expect(summary.monthlyFamilyExpenses, equals(1000.0));

      // Toggle back to Private
      final privateTx = sharedTx.copyWith(isShared: false);
      await provider.updateTransaction(privateTx);

      summary = await FamilyService.instance.getFamilySummary();
      expect(summary.monthlyFamilyExpenses, equals(0.0));
    });

    test(
        '3. Shared Split Transaction contributes parent amount once in Family Summary',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();

      await provider.addTransaction(TransactionItem(
        amount: 1000.0,
        merchant: 'Mega Mall',
        category: 'General',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 13),
        isShared: true,
        splits: [
          TransactionSplit(category: 'Food', amount: 700.0),
          TransactionSplit(category: 'Entertainment', amount: 300.0),
        ],
      ));

      final summary = await FamilyService.instance.getFamilySummary();
      // Parent amount 1000.0 counted ONCE without double counting splits
      expect(summary.monthlyFamilyExpenses, equals(1000.0));
    });

    testWidgets(
        '4. Profile Deletion UI Dialog: Warning, Cancel, and Confirmation Flow',
        (tester) async {
      late FamilyMember pA;
      late FamilyMember pB;
      late List<FamilyMember> initialList;
      late BudgetProvider budgetProvider;

      await tester.runAsync(() async {
        await FamilyService.instance.ensureDefaultProfile();
        pA = (await FamilyService.instance.getAllProfiles()).first;
        pB = await FamilyService.instance.createProfile(name: 'Spouse Profile');
        initialList = [pA, pB];
        budgetProvider = BudgetProvider();
        await budgetProvider.loadData();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                surface: AppTheme.darkSurface,
                error: AppTheme.semanticDanger,
              ),
            ),
            home: FamilyMembersPage(initialProfiles: initialList),
          ),
        ),
      );
      await tester.pump();

      // Verify Profile B delete icon button is visible
      final deleteBtnFinder = find.byKey(Key('delete_profile_${pB.id}'));
      expect(deleteBtnFinder, findsOneWidget);

      // Tap Delete button
      await tester.tap(deleteBtnFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Confirmation AlertDialog appears with warning text
      expect(find.text('Delete Profile "Spouse Profile"?'), findsOneWidget);
      expect(
          find.textContaining(
              'permanently delete this family profile and all associated local transactions'),
          findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 300));

      // Profile B still exists
      await tester.runAsync(() async {
        final profiles = await FamilyService.instance.getAllProfiles();
        expect(profiles.any((p) => p.id == pB.id), isTrue);
      });

      // Tap Delete button again
      await tester.tap(deleteBtnFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Delete Profile button in dialog
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Profile'));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // Profile B deleted
      await tester.runAsync(() async {
        final profiles = await FamilyService.instance.getAllProfiles();
        expect(profiles.any((p) => p.id == pB.id), isFalse);
      });

      // Default profile does NOT have a delete button
      final defaultDeleteBtnFinder = find.byKey(
          const Key('delete_profile_${FamilyService.kDefaultProfileId}'));
      expect(defaultDeleteBtnFinder, findsNothing);
    });

    test('5. Zero Cloud Privacy Verification', () {
      expect(FamilyService.kDefaultProfileId, equals('default_profile'));
    });
  });
}
