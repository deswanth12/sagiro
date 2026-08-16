import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/account_model.dart';
import '../../services/database_helper.dart';

class AccountRepository {
  static final AccountRepository instance = AccountRepository._init();
  AccountRepository._init();

  final List<AccountModel> _memoryStore = [];

  Future<List<AccountModel>> getAccounts() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return List.unmodifiable(_memoryStore);

    try {
      final rows =
          await db.query('accounts', orderBy: 'isPrimary DESC, updatedAt DESC');
      if (rows.isEmpty) return List.unmodifiable(_memoryStore);
      return rows.map((r) => AccountModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('AccountRepository: query error $e');
      return List.unmodifiable(_memoryStore);
    }
  }

  Future<void> saveAccount(AccountModel account) async {
    final idx = _memoryStore.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _memoryStore[idx] = account;
    } else {
      _memoryStore.add(account);
    }

    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    try {
      await db.insert(
        'accounts',
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('AccountRepository: insert error $e');
    }
  }

  Future<List<AccountModel>> searchAccounts(String query) async {
    final all = await getAccounts();
    if (query.trim().isEmpty) return all;

    final q = query.toLowerCase();
    return all.where((a) {
      return a.nickname.toLowerCase().contains(q) ||
          a.bankName.toLowerCase().contains(q) ||
          a.maskedAccountNumber.toLowerCase().contains(q);
    }).toList();
  }
}
