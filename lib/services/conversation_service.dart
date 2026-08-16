import 'database_helper.dart';
import 'subscription_detector.dart';
import '../rag/rag_service.dart';
import '../family_engine/services/family_service.dart';

class ConversationResult {
  final String text;
  final List<String> suggestions;
  final String? actionTitle;
  final Function()? onActionPressed;

  ConversationResult({
    required this.text,
    required this.suggestions,
    this.actionTitle,
    this.onActionPressed,
  });
}

class ConversationService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final RagService _ragService = RagService();

  Future<ConversationResult> processQuery(String query) async {
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
      query: query,
      transactions: transactions,
      subscriptions: subscriptions,
      monthlyBudget: monthlyBudget,
    );

    return ConversationResult(
      text: result.response.toFormattedString(),
      suggestions: result.response.followUpQuestions,
    );
  }
}
