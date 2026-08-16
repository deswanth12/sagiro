import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/subscription.dart';
import '../models/merchant_stats.dart';
import '../models/budget_forecast.dart';
import '../models/money_mission.dart';
import '../models/habit_loop.dart';
import '../models/savings_goal.dart';
import '../models/upcoming_bill.dart';
import '../utils/month_range.dart';
import '../services/database_helper.dart';
import '../rag/financial_ai_engine.dart';
import '../services/smart_rules_service.dart';
import '../services/subscription_detector.dart';
import '../services/merchant_intelligence_service.dart';
import '../services/budget_forecast_service.dart';
import '../services/mission_service.dart';
import '../services/habit_loop_service.dart';
import '../family_engine/services/family_service.dart';
import '../models/transaction_draft.dart';
import '../services/canonical_ingestion_service.dart';

/// BudgetProvider — Central state manager for Sagiro.
///
/// STRICT RULE: All analytics are computed from real transaction data only.
/// No hardcoded values. No fabricated metrics. Empty state if no data.
class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SmartRulesService _smartRules = SmartRulesService();

  List<TransactionItem> _transactions = [];
  List<SavingsGoal> _savingsGoals = [];
  List<UpcomingBill> _upcomingBills = [];
  double _monthlyBudget = 0.0;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  // ── Undo History Stack & Data Freshness ───────────────────────────
  final List<List<TransactionItem>> _undoStack = [];
  DateTime? _lastUpdatedTimestamp;

  // ── Cached Analytics (invalidated on loadData) ────────────────────
  Map<String, double>? _cachedCategoryBreakdown;
  List<SubscriptionItem>? _cachedSubscriptions;
  List<MerchantStats>? _cachedTopMerchants;
  BudgetForecast? _cachedForecast;
  double? _cachedMonthSpend;
  double? _cachedTodaySpend;

  String _activeProfileId = 'default_profile';

  // ── Public Getters ────────────────────────────────────────────────
  List<TransactionItem> get transactions => _transactions;
  List<TransactionItem> get filteredTransactions => _filteredTransactions();
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<UpcomingBill> get upcomingBills => _upcomingBills;
  double get monthlyBudget => _monthlyBudget;
  bool get hasBudget => _monthlyBudget > 0;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get activeProfileId => _activeProfileId;

  BudgetProvider() {
    Future.microtask(loadData);
  }

  /// Loads profile-scoped data from SQLite and invalidates analytics cache.
  Future<void> loadData() async {
    try {
      _activeProfileId = await FamilyService.instance.getActiveProfileId();
      final budgetStr =
          await _dbHelper.getSetting('monthly_budget_$_activeProfileId') ??
              await _dbHelper.getSetting('monthly_budget');
      if (budgetStr != null) {
        _monthlyBudget = double.tryParse(budgetStr) ?? 0.0;
      } else {
        _monthlyBudget = 0.0;
      }
      _transactions =
          await _dbHelper.getAllTransactions(profileId: _activeProfileId);

      // Load savings goals from SQLite
      final rawGoals = await _dbHelper.getAllSavingsGoals();
      _savingsGoals = rawGoals
          .map((m) => SavingsGoal(
                id: m['id'] as String,
                title: m['title'] as String,
                targetAmount: (m['targetAmount'] as num).toDouble(),
                currentAmount: (m['currentAmount'] as num).toDouble(),
                targetDate: DateTime.parse(m['targetDate'] as String),
                emoji: m['emoji'] as String,
              ))
          .toList();

      final rawBills = await _dbHelper.getAllUpcomingBills();
      _upcomingBills = rawBills.map((m) => UpcomingBill.fromMap(m)).toList();

      _invalidateCache();
      _lastUpdatedTimestamp = DateTime.now();
    } catch (e) {
      debugPrint('BudgetProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switches active family profile and reloads isolated profile data
  Future<void> switchProfile(String newProfileId) async {
    if (_activeProfileId == newProfileId) return;
    _isLoading = true;
    notifyListeners();
    await FamilyService.instance.setActiveProfileId(newProfileId);
    await loadData();
  }

  /// Label showing data freshness (e.g., "Updated 4 min ago")
  String get dataFreshnessLabel {
    if (_lastUpdatedTimestamp == null) return 'Updated just now';
    final diff = DateTime.now().difference(_lastUpdatedTimestamp!);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hr ago';
    return 'Updated yesterday';
  }

  /// Whether data has not been updated in over 24 hours
  bool get isDataStale {
    if (_lastUpdatedTimestamp == null) return false;
    return DateTime.now().difference(_lastUpdatedTimestamp!).inHours >= 24;
  }

  void _pushUndoState() {
    _undoStack.add(List<TransactionItem>.from(_transactions));
    if (_undoStack.length > 10) _undoStack.removeAt(0); // keep max 10 states
  }

  Future<void> undoLastAction() async {
    if (_undoStack.isEmpty) return;
    final previousState = _undoStack.removeLast();
    // Reconcile DB with previousState
    final db = await _dbHelper.database;
    if (db != null) {
      await db.delete('transactions');
      for (final tx in previousState) {
        await db.insert('transactions', tx.toMap());
      }
    }
    await loadData();
  }

  void _invalidateCache() {
    _cachedCategoryBreakdown = null;
    _cachedSubscriptions = null;
    _cachedTopMerchants = null;
    _cachedForecast = null;
    _cachedMonthSpend = null;
    _cachedTodaySpend = null;
    FinancialAiEngine.invalidateCache();
  }

  List<TransactionItem> _filteredTransactions() {
    return _transactions.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          t.category == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<SingleIngestionResult> addTransaction(TransactionItem item,
      {bool allowAutoMerge = true}) async {
    _pushUndoState();
    final category =
        await _smartRules.matchCategory(item.merchant, item.notes ?? '');
    final itemWithProfile =
        (item.profileId.isEmpty || item.profileId == 'default_profile')
            ? item.copyWith(profileId: _activeProfileId)
            : item;
    final categorizedItem = itemWithProfile.copyWith(
        category: category == 'General' ? item.category : category);

    final draft = TransactionDraft.fromTransactionItem(categorizedItem);
    final result = await CanonicalIngestionService.instance.ingestSingle(
      draft: draft,
      profileId: _activeProfileId,
      allowAutoMerge: allowAutoMerge,
    );

    await loadData();
    return result;
  }

  Future<IngestionCommitResult> commitIngestionBatch(
      List<IngestionItemDecision> decisions) async {
    if (decisions.isEmpty) {
      return IngestionCommitResult(
        insertedCount: 0,
        mergedCount: 0,
        skippedCount: 0,
      );
    }
    _pushUndoState();
    final result = await CanonicalIngestionService.instance.commitBatch(
      decisions: decisions,
      profileId: _activeProfileId,
    );
    await loadData();
    return result;
  }

  Future<BatchInsertResult> addTransactionsBatch(
      List<TransactionItem> items) async {
    if (items.isEmpty) {
      return BatchInsertResult(insertedCount: 0, failedCount: 0, errors: []);
    }
    _pushUndoState();
    final categorizedDrafts = <TransactionDraft>[];
    for (final item in items) {
      final category =
          await _smartRules.matchCategory(item.merchant, item.notes ?? '');
      final itemWithProfile =
          (item.profileId.isEmpty || item.profileId == 'default_profile')
              ? item.copyWith(profileId: _activeProfileId)
              : item;
      final categorizedItem = itemWithProfile.copyWith(
          category: category == 'General' ? item.category : category);
      categorizedDrafts
          .add(TransactionDraft.fromTransactionItem(categorizedItem));
    }

    final preview = await CanonicalIngestionService.instance.previewBatch(
      incoming: categorizedDrafts,
      profileId: _activeProfileId,
    );

    final decisions = preview.items.map((p) {
      if (p.isInvalid || p.suggestedAction == IngestionAction.skipDuplicate) {
        return IngestionItemDecision(
          draft: p.draft,
          userChoice: IngestionUserChoice.skip,
        );
      }
      if (p.suggestedAction == IngestionAction.mergeExisting) {
        return IngestionItemDecision(
          draft: p.draft,
          userChoice: IngestionUserChoice.autoMerge,
          targetExisting: p.matchedExistingTransaction,
        );
      }
      return IngestionItemDecision(
        draft: p.draft,
        userChoice: IngestionUserChoice.forceNew,
      );
    }).toList();

    final commitResult = await CanonicalIngestionService.instance.commitBatch(
      decisions: decisions,
      profileId: _activeProfileId,
    );

    await loadData();
    return BatchInsertResult(
      insertedCount: commitResult.insertedCount + commitResult.mergedCount,
      failedCount: commitResult.skippedCount,
      errors: commitResult.errors,
    );
  }

  Future<void> deleteTransaction(int id) async {
    _pushUndoState();
    await _dbHelper.deleteTransaction(id);
    await loadData();
  }

  Future<void> updateCategory(TransactionItem item, String newCategory) async {
    _pushUndoState();
    final updated = item.copyWith(
        category: newCategory, userCategory: newCategory, splits: null);
    await _dbHelper.updateTransaction(updated);
    await loadData();
  }

  Future<void> updateTransaction(TransactionItem item) async {
    _pushUndoState();
    await _dbHelper.updateTransaction(item);
    await loadData();
  }

  Future<void> updateMonthlyBudget(double newBudget) async {
    _monthlyBudget = newBudget;
    await _dbHelper.setSetting('monthly_budget', newBudget.toString());
    _invalidateCache();
    notifyListeners();
  }

  // ── Real User Goals & Bills Management ──────────────────────────────
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _dbHelper.insertSavingsGoal({
      'id': goal.id,
      'title': goal.title,
      'targetAmount': goal.targetAmount,
      'currentAmount': goal.currentAmount,
      'targetDate': goal.targetDate.toIso8601String(),
      'emoji': goal.emoji,
    });
    _savingsGoals.add(goal);
    notifyListeners();
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _dbHelper.deleteSavingsGoal(id);
    _savingsGoals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> addUpcomingBill(UpcomingBill bill) async {
    await _dbHelper.insertUpcomingBill(bill.toMap());
    _upcomingBills.add(bill);
    _invalidateCache();
    notifyListeners();
  }

  Future<void> updateUpcomingBill(UpcomingBill bill) async {
    await _dbHelper.updateUpcomingBill(bill.toMap());
    final index = _upcomingBills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      _upcomingBills[index] = bill;
    }
    _invalidateCache();
    notifyListeners();
  }

  Future<void> toggleUpcomingBillActive(String id) async {
    final index = _upcomingBills.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _upcomingBills[index]
          .copyWith(isActive: !_upcomingBills[index].isActive);
      await updateUpcomingBill(updated);
    }
  }

  Future<void> deleteUpcomingBill(String id) async {
    await _dbHelper.deleteUpcomingBill(id);
    _upcomingBills.removeWhere((b) => b.id == id);
    _invalidateCache();
    notifyListeners();
  }

  // ── Cached Calculated Analytics ──────────────────────────────────
  double get monthSpend => calculateMonthSpend();

  double calculateMonthSpend({DateTime? targetDate}) {
    if (targetDate == null && _cachedMonthSpend != null) {
      return _cachedMonthSpend!;
    }
    final range = MonthRange.forDate(targetDate ?? DateTime.now());
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final t in _transactions) {
      if (range.contains(t.date)) {
        if (t.type == TransactionType.debit) {
          totalDebit += t.amount;
        } else if (t.type == TransactionType.credit) {
          totalCredit += t.amount;
        }
      }
    }

    final net = (totalDebit - totalCredit).clamp(0.0, double.infinity);
    if (targetDate == null) _cachedMonthSpend = net;
    return net;
  }

  double get todaySpend => calculateTodaySpend();

  double calculateTodaySpend({DateTime? targetDate}) {
    if (targetDate == null && _cachedTodaySpend != null) {
      return _cachedTodaySpend!;
    }
    final now = targetDate ?? DateTime.now();
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final t in _transactions) {
      final local = t.date.toLocal();
      if (local.year == now.year &&
          local.month == now.month &&
          local.day == now.day) {
        if (t.type == TransactionType.debit) {
          totalDebit += t.amount;
        } else if (t.type == TransactionType.credit) {
          totalCredit += t.amount;
        }
      }
    }

    final net = (totalDebit - totalCredit).clamp(0.0, double.infinity);
    if (targetDate == null) _cachedTodaySpend = net;
    return net;
  }

  double get totalActiveFixedExpenses {
    return _upcomingBills
        .where((b) => b.isActive && !b.isPaid)
        .fold<double>(0.0, (s, b) => s + b.amount);
  }

  double get availableBuffer => calculateAvailableBuffer();

  double calculateAvailableBuffer({DateTime? targetDate}) {
    final spend = calculateMonthSpend(targetDate: targetDate);
    return (_monthlyBudget - spend - totalActiveFixedExpenses)
        .clamp(0.0, _monthlyBudget);
  }

  double get dailySafeSpendingLimit => calculateSafeToday();

  double calculateSafeToday({DateTime? targetDate}) {
    if (!hasBudget) return 0.0;
    final now = targetDate ?? DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (totalDaysInMonth - now.day + 1).clamp(1, 31);
    final buffer = calculateAvailableBuffer(targetDate: targetDate);
    return buffer / remainingDays;
  }

  String get safeTodaySubtitle {
    if (!hasBudget) {
      return 'Set a monthly budget to calculate Safe Today.';
    }
    if (_transactions.isEmpty) {
      return 'Daily limit based on monthly budget';
    }
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return 'Available to spend today (${currency.format(todaySpend)} spent today)';
  }

  Map<String, double> get categoryBreakdown {
    if (_cachedCategoryBreakdown != null) return _cachedCategoryBreakdown!;
    final map = <String, double>{};
    final now = DateTime.now();

    for (final t in _transactions) {
      final local = t.date.toLocal();
      if (t.type == TransactionType.debit &&
          local.year == now.year &&
          local.month == now.month) {
        if (t.isSplit) {
          for (final split in t.splits!) {
            map[split.category] = (map[split.category] ?? 0.0) + split.amount;
          }
        } else {
          map[t.category] = (map[t.category] ?? 0.0) + t.amount;
        }
      }
    }
    _cachedCategoryBreakdown = map;
    return _cachedCategoryBreakdown!;
  }

  List<SubscriptionItem> get activeSubscriptions {
    _cachedSubscriptions ??=
        SubscriptionDetectorService.detectSubscriptions(_transactions);
    return _cachedSubscriptions!;
  }

  double get totalMonthlySubscriptionCost {
    return activeSubscriptions.fold<double>(
        0.0, (sum, item) => sum + item.averageAmount);
  }

  List<MerchantStats> get topMerchants {
    _cachedTopMerchants ??=
        MerchantIntelligenceService.getTopMerchants(_transactions);
    return _cachedTopMerchants!;
  }

  BudgetForecast get budgetForecast {
    _cachedForecast ??= BudgetForecastService.calculateForecast(
      _transactions,
      _monthlyBudget,
    );
    return _cachedForecast!;
  }

  int get noSpendDaysCount =>
      HabitLoopService.getNoSpendDaysCount(_transactions);
  DailyMoneyMission get todayMission =>
      MissionService.getTodayMission(_transactions, todaySpend);
  MoneyWeatherForecast get moneyWeatherForecast =>
      HabitLoopService.getWeatherForecast(
        todaySpend: todaySpend,
        dailySafeLimit: dailySafeSpendingLimit,
        predictedMonthEnd: budgetForecast.predictedMonthEnd,
        monthlyBudget: _monthlyBudget,
        hasTransactions: _transactions.isNotEmpty,
      );
}
