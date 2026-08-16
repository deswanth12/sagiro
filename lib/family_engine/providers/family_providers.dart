import 'package:flutter/foundation.dart';
import '../models/family_models.dart';
import '../services/family_service.dart';

class FamilyStateNotifier extends ChangeNotifier {
  FamilySummary? _summary;
  List<FamilyMember> _members = [];
  List<FamilyBudget> _sharedBudgets = [];
  List<FamilyGoal> _sharedGoals = [];
  bool _isLoading = false;

  FamilySummary? get summary => _summary;
  List<FamilyMember> get members => _members;
  List<FamilyBudget> get sharedBudgets => _sharedBudgets;
  List<FamilyGoal> get sharedGoals => _sharedGoals;
  bool get isLoading => _isLoading;

  Future<void> fetchSummary() async {
    _isLoading = true;
    notifyListeners();
    _summary = await FamilyService.instance.getFamilySummary();
    _members = await FamilyService.instance.getAllProfiles();
    _sharedBudgets = await FamilyService.instance.getSharedBudgets();
    _sharedGoals = await FamilyService.instance.getSharedGoals();
    _isLoading = false;
    notifyListeners();
  }
}
