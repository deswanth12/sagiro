import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/smart_rules_service.dart';
import 'package:sagiro/services/database_helper.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Sagiro Timeline Transaction Editing Regression Tests', () {
    late BudgetProvider provider;

    setUp(() async {
      provider = BudgetProvider();
      await DatabaseHelper.instance.clearAllData();
      await provider.loadData();
    });

    test(
        '1-7. Edit category creates userCategory override while preserving original SMS and ID without duplicates',
        () async {
      final initialTx = TransactionItem(
        amount: 25000.0,
        merchant: 'Corp Salary Deposit',
        category: 'Salary',
        type: TransactionType.credit,
        source: TransactionSource.sms,
        date: DateTime(2026, 8, 11),
        account: 'SBI Bank',
        rawSms: 'Credit of Rs 25000.00 to SBI A/c ... Salary from Corp',
      );

      await provider.addTransaction(initialTx);
      expect(provider.transactions.length, equals(1));
      final savedTx = provider.transactions.first;
      expect(savedTx.category, equals('Salary'));
      expect(savedTx.rawSms, isNull);

      // User changes Salary -> Freelance
      final updatedTx = savedTx.copyWith(
        userCategory: 'Freelance',
      );

      await provider.updateTransaction(updatedTx);

      expect(provider.transactions.length, equals(1));
      final editedTx = provider.transactions.first;

      // 2 & 3. Effective category is now Freelance
      expect(editedTx.category, equals('Freelance'));
      expect(editedTx.userCategory, equals('Freelance'));

      // 4. Raw SMS is null per P2-01 privacy policy
      expect(editedTx.rawSms, isNull);

      // 5. Original detected category preserved in originalCategory
      expect(editedTx.originalCategory, equals('Salary'));

      // 6. ID remains unchanged
      expect(editedTx.id, equals(savedTx.id));

      // 7. No duplicate transactions created
      expect(provider.transactions.length, equals(1));
    });

    test('8-11. User edits amount, date, merchant, and note cleanly', () async {
      final initialTx = TransactionItem(
        amount: 8000.0,
        merchant: 'Landlord Rent',
        category: 'Rent',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime(2026, 8, 1),
      );

      await provider.addTransaction(initialTx);
      final savedTx = provider.transactions.first;

      final updatedTx = savedTx.copyWith(
        amount: 8500.0,
        merchant: 'Home Rent',
        notes: 'Updated August rent payment with water charges',
        date: DateTime(2026, 8, 5),
      );

      await provider.updateTransaction(updatedTx);

      expect(provider.transactions.length, equals(1));
      final edited = provider.transactions.first;
      expect(edited.amount, equals(8500.0));
      expect(edited.merchant, equals('Home Rent'));
      expect(edited.notes, contains('water charges'));
      expect(edited.date.day, equals(5));
    });

    test('12. User deletes transaction cleanly', () async {
      final tx = TransactionItem(
        amount: 500.0,
        merchant: 'Zomato',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
      );

      await provider.addTransaction(tx);
      expect(provider.transactions.length, equals(1));
      final savedId = provider.transactions.first.id!;

      await provider.deleteTransaction(savedId);
      expect(provider.transactions.isEmpty, isTrue);
    });

    test(
        '13-14. App reload preserves edits and existing transactions remain intact',
        () async {
      final tx1 = TransactionItem(
        amount: 1200.0,
        merchant: 'Swiggy',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
      );
      final tx2 = TransactionItem(
        amount: 3000.0,
        merchant: 'Electricity Board',
        category: 'Bills',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime.now(),
      );

      await provider.addTransaction(tx1);
      await provider.addTransaction(tx2);

      expect(provider.transactions.length, equals(2));

      // Edit tx1 category Food -> Dining
      final target =
          provider.transactions.firstWhere((t) => t.merchant == 'Swiggy');
      await provider
          .updateTransaction(target.copyWith(userCategory: 'Dining Out'));

      // Simulate App Reload
      final newProvider = BudgetProvider();
      await newProvider.loadData();

      expect(newProvider.transactions.length, equals(2));
      final reloadedSwiggy =
          newProvider.transactions.firstWhere((t) => t.merchant == 'Swiggy');
      expect(reloadedSwiggy.category, equals('Dining Out'));
    });

    test(
        '15-16. Imported (CSV) and SMS-derived transactions support full editing',
        () async {
      final csvTx = TransactionItem(
        amount: 1500.0,
        merchant: 'Amazon Purchase',
        category: 'Shopping',
        type: TransactionType.debit,
        source: TransactionSource.csv,
        date: DateTime.now(),
      );

      final smsTx = TransactionItem(
        amount: 250.0,
        merchant: 'Uber Ride',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
        rawSms: 'Debited Rs 250 for Uber',
      );

      await provider.addTransaction(csvTx);
      await provider.addTransaction(smsTx);

      final editCsv = provider.transactions
          .firstWhere((t) => t.source == TransactionSource.csv);
      final editSms = provider.transactions
          .firstWhere((t) => t.source == TransactionSource.sms);

      await provider
          .updateTransaction(editCsv.copyWith(userCategory: 'Personal Care'));
      await provider
          .updateTransaction(editSms.copyWith(userCategory: 'Commute'));

      expect(
          provider.transactions
              .firstWhere((t) => t.source == TransactionSource.csv)
              .category,
          equals('Personal Care'));
      expect(
          provider.transactions
              .firstWhere((t) => t.source == TransactionSource.sms)
              .category,
          equals('Commute'));
    });

    test(
        'Category-learning rule assigns preferred category to future merchant transactions',
        () async {
      final smartRules = SmartRulesService();
      await smartRules.learnRule('ACME TECHNOLOGIES', 'Monthly Income');

      final category = await smartRules.matchCategory(
          'ACME TECHNOLOGIES', 'Salary credited');
      expect(category, equals('Monthly Income'));
    });
  });
}
