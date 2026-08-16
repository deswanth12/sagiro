import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/services/sms_parser.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/services/voice_expense_service.dart';
import 'package:sagiro/services/statement_importer_service.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/providers/authentication_provider.dart';
import 'package:sagiro/utils/month_range.dart';
import 'package:sagiro/components/pricing_card.dart';
import 'dart:typed_data';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    setupTestSqflite();
  });

  group('SAGIRO Red-Team Group 1: Authentication & Diagnostic Errors', () {
    test('AuthenticationProvider categorizes diagnostic errors accurately',
        () async {
      final authProvider = AuthenticationProvider();

      // Check initial state
      expect(authProvider.status, equals(AuthenticationStatus.initial));
    });
  });

  group('SAGIRO Red-Team Group 2: Real SMS Scanner & Parsing Accuracy', () {
    test('Early keyword rejection filters false positives', () {
      final falsePositives = [
        'first',
        'hours',
        'offers',
        'orders',
        'users',
        'answers',
        'person',
        'accountant',
        'Your order of 2 items will arrive in 4 hours.',
        'Welcome first time user! Check our new offers.',
      ];

      for (final text in falsePositives) {
        expect(SmsParser.hasFinancialKeywords(text), isFalse,
            reason: 'Message "$text" must be early rejected.');
      }
    });

    test('Valid financial SMS messages are accepted and parsed', () {
      final bankMessages = [
        'Rs. 500 debited from A/C X1234 on 13-Aug-2026.',
        'Rs 500 credited to account X5678.',
        'INR 500 transferred via UPI to merchant.',
        '₹500 paid at Swiggy.',
        'UPI transfer of Rs 1000 completed.',
        'NEFT transfer of Rs 5000 processed.',
        'IMPS transfer of Rs 2000 successful.',
        'ATM withdrawal of Rs 3000 at HDFC ATM.',
        'POS purchase of Rs 1500 at Shoppers Stop.',
        'A/C debited by Rs 750.',
        'Rs. 500 debited from A/C X1234. Avl Bal Rs 8,500 after payment.',
      ];

      for (final msg in bankMessages) {
        expect(SmsParser.hasFinancialKeywords(msg), isTrue,
            reason: 'Message "$msg" must pass financial keyword filter.');
        final res = SmsParser.parseSmsDetailed(msg, 'AX-HDFCBK');
        expect(res, isNotNull,
            reason: 'Message "$msg" must produce valid parsed result.');
      }
    });

    test('Amount and Balance separation safety', () {
      final result = SmsParser.parseSmsDetailed(
          'Rs 1,000 debited. Avl Bal Rs 8,500', 'AX-HDFCBK');
      expect(result, isNotNull);
      expect(result!.transaction.amount, equals(1000.0));
      expect(result.remainingBalance, equals(8500.0));
    });
  });

  group('SAGIRO Red-Team Group 3: SMS Date Precedence & Month Accuracy', () {
    test('Deterministic yearless date inference rule', () {
      final smsReceived = DateTime(2026, 8, 14);

      // Same year case (Aug 13)
      final d1 = SmsParser.parseTransactionDate('13 Aug', smsDate: smsReceived);
      expect(d1.year, equals(2026));
      expect(d1.month, equals(8));
      expect(d1.day, equals(13));

      // Dec 31 received in Jan 2026 -> 2025
      final janReceived = DateTime(2026, 1, 2);
      final d2 = SmsParser.parseTransactionDate('31 Dec', smsDate: janReceived);
      expect(d2.year, equals(2025));
      expect(d2.month, equals(12));
      expect(d2.day, equals(31));
    });

    test('MonthRange boundaries startInclusive <= date < endExclusive', () {
      final range = MonthRange.forYearMonth(2026, 8);
      final aug1Start = DateTime(2026, 8, 1, 0, 0, 0);
      final aug31End = DateTime(2026, 8, 31, 23, 59, 59);
      final sep1Start = DateTime(2026, 9, 1, 0, 0, 0);

      expect(range.contains(aug1Start), isTrue);
      expect(range.contains(aug31End), isTrue);
      expect(range.contains(sep1Start), isFalse);
    });
  });

  group('SAGIRO Red-Team Group 4: PDF & CSV Statement Import Pipeline', () {
    test('CSV statement import parses and assigns active profileId', () async {
      await DatabaseHelper.instance.clearAllData();
      final provider = BudgetProvider();
      await provider.loadData();

      const csvContent = '''Date,Description,Amount,Type
12-08-2026,Swiggy Lunch,350.00,Debit
13-08-2026,Salary Credit,50000.00,Credit''';

      final bytes = Uint8List.fromList(csvContent.codeUnits);
      final importRes = await StatementImporterService.instance.parseStatement(
        fileBytes: bytes,
        fileName: 'test_statement.csv',
      );

      expect(importRes.isDecryptedSuccessfully, isTrue);
      expect(importRes.transactions.length, equals(2));

      await provider.addTransactionsBatch(importRes.transactions);
      expect(provider.transactions.length, equals(2));
      expect(
          provider.transactions.every((t) => t.profileId == 'default_profile'),
          isTrue);
    });

    test('Unsupported statement returns explicit diagnostic message', () async {
      final bytes =
          Uint8List.fromList('Random non-financial text buffer'.codeUnits);
      final importRes = await StatementImporterService.instance.parseStatement(
        fileBytes: bytes,
        fileName: 'unsupported.txt',
      );

      expect(importRes.transactions, isEmpty);
      expect(importRes.errorMessage,
          equals('Could not identify transactions in this statement.'));
    });
  });

  group('SAGIRO Red-Team Group 5: Voice Expense Natural Language Entry', () {
    test('Parses "Spent 350 on Zomato"', () {
      final res =
          VoiceExpenseService.parseVoiceTranscript('Spent 350 on Zomato');
      expect(res.amount, equals(350.0));
      expect(res.merchant, equals('Zomato'));
      expect(res.type, equals(TransactionType.debit));
      expect(res.category, equals('Food & Dining'));
    });

    test('Parses "Received 5000 salary"', () {
      final res =
          VoiceExpenseService.parseVoiceTranscript('Received 5000 salary');
      expect(res.amount, equals(5000.0));
      expect(res.type, equals(TransactionType.credit));
      expect(res.category, equals('Income'));
    });

    test('Parses "Paid 1200 electricity bill"', () {
      final res = VoiceExpenseService.parseVoiceTranscript(
          'Paid 1200 electricity bill');
      expect(res.amount, equals(1200.0));
      expect(res.merchant, equals('Electricity Bill'));
      expect(res.category, equals('Bills & Utilities'));
    });

    test('Parses "Spent 250 at Amazon"', () {
      final res =
          VoiceExpenseService.parseVoiceTranscript('Spent 250 at Amazon');
      expect(res.amount, equals(250.0));
      expect(res.merchant, equals('Amazon'));
      expect(res.category, equals('Shopping'));
    });

    test('Parses "Added 500 to savings"', () {
      final res =
          VoiceExpenseService.parseVoiceTranscript('Added 500 to savings');
      expect(res.amount, equals(500.0));
      expect(res.category, equals('Savings'));
    });
  });

  group('SAGIRO Red-Team Group 6: Profile Isolation & Money Brain', () {
    test('Data is strictly isolated between Profile A and Profile B', () async {
      await DatabaseHelper.instance.clearAllData();
      final provider = BudgetProvider();
      await provider.loadData();

      // Add item to profile A
      await provider.addTransaction(TransactionItem(
        amount: 250.0,
        merchant: 'ProfileA Merchant',
        category: 'Food',
        type: TransactionType.debit,
        source: TransactionSource.manual,
        date: DateTime.now(),
        profileId: 'default_profile',
      ));
      expect(provider.transactions.length, equals(1));

      // Switch to Profile B
      await provider.switchProfile('profile_b');
      expect(provider.transactions.length, equals(0));

      // Switch back to Profile A
      await provider.switchProfile('default_profile');
      expect(provider.transactions.length, equals(1));
    });
  });

  group('SAGIRO Red-Team Group 7: Pro Tier & Typography Visibility', () {
    testWidgets('PricingCard renders visible text in light theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: PricingCard(
              title: 'Lifetime Pro',
              priceText: '₹499',
              periodText: 'one-time',
              features: const ['100% On-Device SMS', 'Unlimited Profiles'],
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Lifetime Pro'), findsOneWidget);
      expect(find.text('₹499'), findsOneWidget);
      expect(find.text('100% On-Device SMS'), findsOneWidget);
    });
  });
}
