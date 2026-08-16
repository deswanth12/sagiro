import '../models/transaction.dart';
import '../rag/financial_ai_engine.dart';
import '../rag/intent_classifier.dart';
import '../rag/context_builder.dart';

class RagResponse {
  final String text;
  final List<String> suggestions;

  RagResponse({required this.text, required this.suggestions});
}

/// FinancialRagEngine — Legacy Service Bridge to Money Brain RAG Engine.
class FinancialRagEngine {
  final FinancialAiEngine _aiEngine = FinancialAiEngine();

  RagResponse query({
    required String userQuery,
    required List<TransactionItem> transactions,
    required double monthlyBudget,
  }) {
    final intent = IntentClassifier.classify(userQuery);
    final contextPayload = ContextBuilder.buildContextPayload([]);

    final response = _aiEngine.analyze(
      query: userQuery,
      intent: intent,
      contextPayload: contextPayload,
      allTransactions: transactions,
      subscriptions: [],
      monthlyBudget: monthlyBudget,
    );

    return RagResponse(
      text: response.toFormattedString(),
      suggestions: response.followUpQuestions,
    );
  }
}
