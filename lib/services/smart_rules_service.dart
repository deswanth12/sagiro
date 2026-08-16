import '../models/category_rule.dart';
import '../services/database_helper.dart';

class SmartRulesService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Given a merchant name or raw SMS, returns the matching learned category or 'General'
  Future<String> matchCategory(String merchant, String rawText) async {
    final rules = await _dbHelper.getAllRules();
    final combinedLower = '${merchant.toLowerCase()} ${rawText.toLowerCase()}';

    for (final rule in rules) {
      if (combinedLower.contains(rule.keyword.toLowerCase())) {
        return rule.category;
      }
    }
    return 'General';
  }

  /// Learn a new rule when user manually changes a transaction's category
  Future<void> learnRule(String merchant, String newCategory) async {
    if (merchant.trim().isEmpty || merchant == 'Bank Transaction') return;

    final keyword = merchant.trim().toLowerCase();
    final rule = CategoryRule(keyword: keyword, category: newCategory);
    await _dbHelper.insertRule(rule);
  }
}
