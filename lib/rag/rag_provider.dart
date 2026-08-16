import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';
import '../services/subscription_detector.dart';
import '../family_engine/services/family_service.dart';
import 'rag_service.dart';

class RagProvider with ChangeNotifier {
  final RagService _ragService = RagService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isAnalyzing = false;
  MoneyBrainResult? _lastResult;

  bool get isAnalyzing => _isAnalyzing;
  MoneyBrainResult? get lastResult => _lastResult;

  Future<MoneyBrainResult> queryMoneyBrain(String userQuery) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      // Scope to the active profile so Money Brain cannot read another
      // family member's private transactions (Privacy fix: Issue 3).
      final activeProfileId = await FamilyService.instance.getActiveProfileId();
      final transactions =
          await _db.getAllTransactions(profileId: activeProfileId);
      final subscriptions =
          SubscriptionDetectorService.detectSubscriptions(transactions);
      final monthlyBudgetStr = await _db.getSetting('monthly_budget');
      final monthlyBudget = double.tryParse(monthlyBudgetStr ?? '0') ?? 0.0;

      final result = await _ragService.executePipeline(
        query: userQuery,
        transactions: transactions,
        subscriptions: subscriptions,
        monthlyBudget: monthlyBudget,
      );

      _lastResult = result;
      return result;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
}
