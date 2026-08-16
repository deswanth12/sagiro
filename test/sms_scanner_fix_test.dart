import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/family_engine/services/family_service.dart';
import 'package:sagiro/models/transaction.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/services/app_settings_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/services/sms_parser.dart';
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
      try {
        await db.delete('profiles');
      } catch (_) {}
    }
    await AppSettingsService.instance.loadSettings();
  });

  group('SMS Scanner Production-Hardened Regression Test Suite', () {
    test('1. Unknown sender + valid financial SMS -> parsed', () {
      const unknownSender = '140001';
      const body =
          'Rs 450.00 debited from A/C XX1234 on 13-08-26 by VPA swiggy@upi. Ref 998877665544.';
      final res = SmsParser.parseSmsDetailed(body, unknownSender);
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(450.0));
      expect(res.transaction.type, equals(TransactionType.debit));
    });

    test('2. Known sender + valid financial SMS -> parsed', () {
      const knownSender = 'AD-HDFCBK';
      const body =
          'Rs 1,500.00 debited from A/C **4321 on 13-08-26 by VPA swiggy@upi. Ref 628401928471.';
      final res = SmsParser.parseSmsDetailed(body, knownSender);
      expect(res, isNotNull);
      expect(res!.transaction.amount, equals(1500.0));
      expect(res.transaction.type, equals(TransactionType.debit));
    });

    test('3. Unknown sender + normal personal SMS -> rejected', () {
      const unknownSender = '+919876543210';
      const body = 'Hey, let us catch up for coffee this weekend!';
      final res = SmsParser.parseSmsDetailed(body, unknownSender);
      expect(res, isNull);
    });

    test('4. Unknown sender + OTP -> rejected', () {
      const unknownSender = 'VK-JIOOTP';
      const body =
          'Your OTP for login is 482019. Do not share this secret code with anyone.';
      final res = SmsParser.parseSmsDetailed(body, unknownSender);
      expect(res, isNull);
    });

    test(
        '5. Duplicate reference -> rejected & Valid second transaction -> accepted',
        () {
      final existingRefs = ['628401928471'];
      const bodyDuplicate =
          'Rs 1,500.00 debited from A/C **4321 on 13-08-26 by VPA swiggy@upi. Ref 628401928471.';
      const bodyNew =
          'Rs 250.00 debited from A/C **4321 on 13-08-26 by VPA zomato@upi. Ref 776655443322.';

      final resDup = SmsParser.parseSmsDetailed(bodyDuplicate, 'AD-HDFCBK');
      expect(resDup, isNotNull);
      expect(
        existingRefs.contains(resDup!.transaction.transactionReference),
        isTrue,
        reason: 'Duplicate reference must match existing list',
      );

      final resNew = SmsParser.parseSmsDetailed(bodyNew, 'AD-HDFCBK');
      expect(resNew, isNotNull);
      expect(
        existingRefs.contains(resNew!.transaction.transactionReference),
        isFalse,
        reason: 'New valid transaction reference must be accepted',
      );
    });

    test(
        '6. Privacy Guard: rawSms is ALWAYS null on parsed, mapped, and database stored records',
        () async {
      final res = SmsParser.parseSmsDetailed(
        'Rs 999 debited from A/C XX1234 on 13-08-26 at Netflix. Ref 887766554433.',
        'AD-HDFCBK',
      );
      expect(res, isNotNull);
      final tx = res!.transaction;
      expect(tx.rawSms, isNull);

      final map = tx.toMap();
      map.remove('id');
      expect(map['rawSms'], isNull);

      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        final insertedId = await db.insert('transactions', map);
        final rows = await db
            .query('transactions', where: 'id = ?', whereArgs: [insertedId]);
        expect(rows.first['rawSms'], isNull);
      }
    });

    test('7. Family Workspace profile isolation for SMS transactions',
        () async {
      final provider = BudgetProvider();
      await provider.loadData();
      expect(provider.activeProfileId, equals('default_profile'));

      final tx = TransactionItem(
        amount: 450.0,
        merchant: 'Uber',
        category: 'Travel',
        type: TransactionType.debit,
        source: TransactionSource.sms,
        date: DateTime.now(),
        profileId: 'default_profile',
      );

      await provider.addTransaction(tx);
      expect(provider.transactions.length, equals(1));

      // Switch to Profile 2
      final p2 =
          await FamilyService.instance.createProfile(name: 'Family Member');
      await provider.switchProfile(p2.id);

      expect(provider.activeProfileId, equals(p2.id));
      expect(provider.transactions.length, equals(0));
    });
  });
}
