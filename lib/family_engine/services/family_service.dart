import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../services/database_helper.dart';
import '../models/family_models.dart';

class FamilySummary {
  final double totalFamilyNetWorth;
  final double monthlyFamilyIncome;
  final double monthlyFamilyExpenses;
  final double monthlyFamilySavings;
  final int familyHealthScore;
  final int sharedTransactionCount;

  const FamilySummary({
    required this.totalFamilyNetWorth,
    required this.monthlyFamilyIncome,
    required this.monthlyFamilyExpenses,
    required this.monthlyFamilySavings,
    required this.familyHealthScore,
    this.sharedTransactionCount = 0,
  });
}

class FamilyActivityItem {
  final String id;
  final String profileName;
  final String avatarEmoji;
  final String description;
  final double amount;
  final DateTime date;
  final bool isIncome;

  const FamilyActivityItem({
    required this.id,
    required this.profileName,
    required this.avatarEmoji,
    required this.description,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}

class MemberFinancialStats {
  final double sharedExpenses;
  final double sharedIncome;
  final int sharedCount;
  final int privateCount;

  const MemberFinancialStats({
    required this.sharedExpenses,
    required this.sharedIncome,
    required this.sharedCount,
    required this.privateCount,
  });
}

class FamilyService {
  static final FamilyService instance = FamilyService._init();
  FamilyService._init();

  static const String kDefaultProfileId = 'default_profile';

  /// Ensures primary default profile exists in database
  Future<void> ensureDefaultProfile() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    final existing = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [kDefaultProfileId],
    );

    if (existing.isEmpty) {
      await db.insert('profiles', {
        'id': kDefaultProfileId,
        'name': 'Primary Account',
        'avatarEmoji': '👤',
        'role': FamilyRole.owner.name,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': 1,
      });
    }
  }

  /// Creates a new local family profile
  Future<FamilyMember> createProfile({
    required String name,
    String avatarEmoji = '👤',
    FamilyRole role = FamilyRole.adult,
  }) async {
    await ensureDefaultProfile();
    final db = await DatabaseHelper.instance.database;
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Profile name cannot be empty.');
    }

    final id = 'profile_${DateTime.now().microsecondsSinceEpoch}';
    final member = FamilyMember(
      id: id,
      name: cleanName,
      avatarEmoji: avatarEmoji,
      role: role,
      createdAt: DateTime.now(),
      isActive: true,
    );

    if (db != null) {
      await db.insert('profiles', member.toMap());
    }

    return member;
  }

  /// Updates an existing family profile
  Future<void> updateProfile(FamilyMember member) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    await db.update(
      'profiles',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  /// Returns all local family profiles
  Future<List<FamilyMember>> getAllProfiles() async {
    await ensureDefaultProfile();
    final db = await DatabaseHelper.instance.database;
    if (db == null) {
      return [
        FamilyMember(
          id: kDefaultProfileId,
          name: 'Primary Account',
          avatarEmoji: '👤',
          role: FamilyRole.owner,
          createdAt: DateTime.now(),
        )
      ];
    }

    final rows = await db.query('profiles');
    if (rows.isEmpty) {
      return [
        FamilyMember(
          id: kDefaultProfileId,
          name: 'Primary Account',
          avatarEmoji: '👤',
          role: FamilyRole.owner,
          createdAt: DateTime.now(),
        )
      ];
    }

    return rows.map((r) => FamilyMember.fromMap(r)).toList();
  }

  static String _cachedActiveProfileId = kDefaultProfileId;

  /// Gets currently active profile ID asynchronously from SQLite
  Future<String> getActiveProfileId() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return _cachedActiveProfileId;

    final setting = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['active_profile_id'],
    );

    if (setting.isEmpty) {
      _cachedActiveProfileId = kDefaultProfileId;
      return kDefaultProfileId;
    }
    _cachedActiveProfileId =
        setting.first['value'] as String? ?? kDefaultProfileId;
    return _cachedActiveProfileId;
  }

  /// Synchronous getter for fast UI reads
  String get activeProfileIdSync => _cachedActiveProfileId;

  /// Sets currently active profile ID
  Future<void> setActiveProfileId(String profileId) async {
    _cachedActiveProfileId = profileId;
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    await db.insert(
      'settings',
      {'key': 'active_profile_id', 'value': profileId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a profile and all its associated transactions after explicit confirmation
  Future<void> deleteProfile(String profileId) async {
    if (profileId == kDefaultProfileId) {
      throw ArgumentError('Primary default profile cannot be deleted.');
    }

    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete(
        'transactions',
        where: 'profileId = ?',
        whereArgs: [profileId],
      );
      await db.delete(
        'profiles',
        where: 'id = ?',
        whereArgs: [profileId],
      );
    }

    final activeId = await getActiveProfileId();
    if (activeId == profileId) {
      await setActiveProfileId(kDefaultProfileId);
    }
  }

  /// Returns aggregated family summary using only explicitly shared items
  Future<FamilySummary> getFamilySummary() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) {
      return const FamilySummary(
        totalFamilyNetWorth: 0.0,
        monthlyFamilyIncome: 0.0,
        monthlyFamilyExpenses: 0.0,
        monthlyFamilySavings: 0.0,
        familyHealthScore: 0,
        sharedTransactionCount: 0,
      );
    }

    final sharedRows = await db.query(
      'transactions',
      where: 'isShared = 1',
    );

    if (sharedRows.isEmpty) {
      return const FamilySummary(
        totalFamilyNetWorth: 0.0,
        monthlyFamilyIncome: 0.0,
        monthlyFamilyExpenses: 0.0,
        monthlyFamilySavings: 0.0,
        familyHealthScore: 0,
        sharedTransactionCount: 0,
      );
    }

    double income = 0.0;
    double expenses = 0.0;

    for (final row in sharedRows) {
      final amount = (row['amount'] as num).toDouble();
      final type = row['type'] as String?;
      if (type == 'credit') {
        income += amount;
      } else {
        expenses += amount;
      }
    }

    // Deterministic Family Health Score:
    // When shared data exists, health score = (Savings / Income) * 100 clamped to 0-100.
    // If expenses > income, score reflects deficit proportion.
    final healthScore = income > 0
        ? (((income - expenses) / income) * 100).clamp(0.0, 100.0).round()
        : (expenses > 0 ? 30 : 0);

    return FamilySummary(
      totalFamilyNetWorth: (income - expenses),
      monthlyFamilyIncome: income,
      monthlyFamilyExpenses: expenses,
      monthlyFamilySavings: (income - expenses).clamp(0.0, double.infinity),
      familyHealthScore: healthScore,
      sharedTransactionCount: sharedRows.length,
    );
  }

  /// ─── Shared Household Budgets ───────────────────────────────────────────
  Future<List<FamilyBudget>> getSharedBudgets() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return const [];

    final rows = await db.query('family_budgets', orderBy: 'createdAt DESC');
    if (rows.isEmpty) return const [];

    // Get all shared expenses to compute live category spending & member contributions
    final sharedExpenseRows = await db.query(
      'transactions',
      where: 'isShared = 1 AND type = ?',
      whereArgs: ['debit'],
    );

    final profiles = await getAllProfiles();
    final profileMap = {for (var p in profiles) p.id: p.name};

    final List<FamilyBudget> budgets = [];

    for (final row in rows) {
      final id = row['id'] as String;
      final familyId = row['familyId'] as String? ?? 'fam_main';
      final cat = row['category'] as String;
      final limit = (row['limitAmount'] as num).toDouble();

      final memberContribs = <String, double>{};

      for (final txRow in sharedExpenseRows) {
        final txCat = txRow['category'] as String? ?? '';
        if (txCat.toLowerCase() == cat.toLowerCase()) {
          final amt = (txRow['amount'] as num).toDouble();
          final pId = txRow['profileId'] as String? ?? kDefaultProfileId;
          final pName = profileMap[pId] ?? 'Family Member';
          memberContribs[pName] = (memberContribs[pName] ?? 0.0) + amt;
        }
      }

      budgets.add(FamilyBudget(
        id: id,
        familyId: familyId,
        category: cat,
        limitAmount: limit,
        memberContributions: memberContribs,
      ));
    }

    return budgets;
  }

  Future<void> addSharedBudget({
    required String category,
    required double limitAmount,
  }) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    final id = 'fambudget_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('family_budgets', {
      'id': id,
      'familyId': 'fam_main',
      'category': category.trim(),
      'limitAmount': limitAmount,
      'memberContributions': '{}',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteSharedBudget(String budgetId) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    await db.delete(
      'family_budgets',
      where: 'id = ?',
      whereArgs: [budgetId],
    );
  }

  /// ─── Shared Household Goals ─────────────────────────────────────────────
  Future<List<FamilyGoal>> getSharedGoals() async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return const [];

    final rows = await db.query('family_goals', orderBy: 'createdAt DESC');
    if (rows.isEmpty) return const [];

    final List<FamilyGoal> goals = [];
    for (final row in rows) {
      final id = row['id'] as String;
      final familyId = row['familyId'] as String? ?? 'fam_main';
      final title = row['title'] as String;
      final targetAmount = (row['targetAmount'] as num).toDouble();

      Map<String, double> memberContributions = {};
      final rawContribs = row['memberContributions'] as String?;
      if (rawContribs != null && rawContribs.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawContribs) as Map<String, dynamic>;
          memberContributions =
              decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
        } catch (_) {}
      }

      goals.add(FamilyGoal(
        id: id,
        familyId: familyId,
        title: title,
        targetAmount: targetAmount,
        memberContributions: memberContributions,
      ));
    }

    return goals;
  }

  Future<void> addSharedGoal({
    required String title,
    required double targetAmount,
  }) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    final id = 'famgoal_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('family_goals', {
      'id': id,
      'familyId': 'fam_main',
      'title': title.trim(),
      'targetAmount': targetAmount,
      'memberContributions': '{}',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> contributeToSharedGoal({
    required String goalId,
    required String memberName,
    required double amount,
  }) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    final rows =
        await db.query('family_goals', where: 'id = ?', whereArgs: [goalId]);
    if (rows.isEmpty) return;

    final row = rows.first;
    Map<String, double> memberContributions = {};
    final rawContribs = row['memberContributions'] as String?;
    if (rawContribs != null && rawContribs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawContribs) as Map<String, dynamic>;
        memberContributions =
            decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }

    memberContributions[memberName] =
        (memberContributions[memberName] ?? 0.0) + amount;

    await db.update(
      'family_goals',
      {'memberContributions': jsonEncode(memberContributions)},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<void> updateSharedBudget({
    required String budgetId,
    required double limitAmount,
  }) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    await db.update(
      'family_budgets',
      {'limitAmount': limitAmount},
      where: 'id = ?',
      whereArgs: [budgetId],
    );
  }

  Future<void> deleteSharedGoal(String goalId) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    await db.delete(
      'family_goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<void> updateSharedGoal({
    required String goalId,
    required String title,
    required double targetAmount,
  }) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return;

    await db.update(
      'family_goals',
      {
        'title': title.trim(),
        'targetAmount': targetAmount,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<MemberFinancialStats> getMemberFinancialStats(String profileId) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) {
      return const MemberFinancialStats(
        sharedExpenses: 0,
        sharedIncome: 0,
        sharedCount: 0,
        privateCount: 0,
      );
    }

    final rows = await db.query(
      'transactions',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );

    double sharedExp = 0.0;
    double sharedInc = 0.0;
    int sharedCount = 0;
    int privateCount = 0;

    for (final row in rows) {
      final isShared = (row['isShared'] as int? ?? 0) == 1;
      final amount = (row['amount'] as num).toDouble();
      final type = row['type'] as String?;

      if (isShared) {
        sharedCount++;
        if (type == 'credit') {
          sharedInc += amount;
        } else {
          sharedExp += amount;
        }
      } else {
        privateCount++;
      }
    }

    return MemberFinancialStats(
      sharedExpenses: sharedExp,
      sharedIncome: sharedInc,
      sharedCount: sharedCount,
      privateCount: privateCount,
    );
  }

  /// ─── Recent Shared Activity ─────────────────────────────────────────────
  Future<List<FamilyActivityItem>> getRecentSharedActivity(
      {int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    if (db == null) return const [];

    final rows = await db.query(
      'transactions',
      where: 'isShared = 1',
      orderBy: 'date DESC',
      limit: limit,
    );

    if (rows.isEmpty) return const [];

    final profiles = await getAllProfiles();
    final profileMap = {for (var p in profiles) p.id: p};

    final List<FamilyActivityItem> items = [];

    for (final row in rows) {
      final id = row['id']?.toString() ?? '';
      final pId = row['profileId'] as String? ?? kDefaultProfileId;
      final profile = profileMap[pId];
      final pName = profile?.name ?? 'Family Member';
      final pAvatar = profile?.avatarEmoji ?? '👤';
      final merchant = row['merchant'] as String? ?? 'Transaction';
      final category = row['category'] as String? ?? 'Shared';
      final amount = (row['amount'] as num).toDouble();
      final type = row['type'] as String?;
      final isCredit = type == 'credit';
      final date =
          DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();

      items.add(FamilyActivityItem(
        id: id,
        profileName: pName,
        avatarEmoji: pAvatar,
        description: '$merchant ($category)',
        amount: amount,
        date: date,
        isIncome: isCredit,
      ));
    }

    return items;
  }
}
