import '../models/transaction.dart';
import '../models/subscription.dart';
import 'intent_classifier.dart';
import 'sagiro_guide_engine.dart';
import 'retriever.dart';
import 'context_builder.dart';
import 'financial_ai_engine.dart';
import 'llm_service.dart';

class MoneyBrainResult {
  final FormattedMoneyBrainResponse response;
  final FinancialIntent intent;
  final ContextPayload contextPayload;

  MoneyBrainResult({
    required this.response,
    required this.intent,
    required this.contextPayload,
  });
}

class RagService {
  final HybridRetriever _retriever = HybridRetriever();
  final FinancialAiEngine _aiEngine = FinancialAiEngine();
  final LlmService _llmService = LlmService();

  // Track last indexed state to avoid redundant re-indexing on every query
  int _lastIndexedTxCount = -1;
  int _lastIndexedSubCount = -1;
  String _lastIndexedProfileKey = '';

  Future<MoneyBrainResult> executePipeline({
    required String query,
    required List<TransactionItem> transactions,
    required List<SubscriptionItem> subscriptions,
    required double monthlyBudget,
  }) async {
    final financialIntent = IntentClassifier.classify(query);

    // 1. If it's a pure app navigation / action request / guide question AND not a personal financial query:
    if (financialIntent == FinancialIntent.appNavigation ||
        financialIntent == FinancialIntent.generalEducation) {
      final guideRes = SagiroGuideEngine.processQuery(
        query: query,
        budgetProvider: null,
      );
      return MoneyBrainResult(
        response: FormattedMoneyBrainResponse(
          answer: guideRes.text,
          reason: 'Sagiro Guide',
          evidence: 'Sagiro Knowledge Base',
          suggestedAction: guideRes.suggestedActionLabel ?? 'Open Screen',
          followUpQuestions: const [],
        ),
        intent: financialIntent,
        contextPayload: ContextPayload(
          formattedContext: 'Sagiro Guide response',
          retrievedDocs: const [],
        ),
      );
    }

    // 2. Smart Index: Re-index if transaction count, subscription count, or profile/tx data changes
    final currentTxCount = transactions.length;
    final currentSubCount = subscriptions.length;
    final currentProfileKey = transactions.isEmpty
        ? ''
        : transactions
            .map((t) => '${t.id}_${t.profileId}_${t.amount}')
            .join('|');

    if (currentTxCount != _lastIndexedTxCount ||
        currentSubCount != _lastIndexedSubCount ||
        currentProfileKey != _lastIndexedProfileKey) {
      _retriever.indexFinancialData(
        transactions: transactions,
        subscriptions: subscriptions,
      );
      _lastIndexedTxCount = currentTxCount;
      _lastIndexedSubCount = currentSubCount;
      _lastIndexedProfileKey = currentProfileKey;
    }

    final retrievedDocs = _retriever.retrieveContext(query, topK: 8);
    final contextPayload = ContextBuilder.buildContextPayload(retrievedDocs);

    // 3. Process through Real SQLite Transaction Calculation Engine
    final engineResponse = _aiEngine.analyze(
      query: query,
      intent: financialIntent,
      contextPayload: contextPayload,
      allTransactions: transactions,
      subscriptions: subscriptions,
      monthlyBudget: monthlyBudget,
    );

    final finalResponse = await _llmService.synthesize(
      userQuery: query,
      engineResponse: engineResponse,
    );

    return MoneyBrainResult(
      response: finalResponse,
      intent: financialIntent,
      contextPayload: contextPayload,
    );
  }

  /// Force a full re-index on next query (call after data import/sync).
  void invalidateIndex() {
    _lastIndexedTxCount = -1;
    _lastIndexedSubCount = -1;
    _lastIndexedProfileKey = '';
    FinancialAiEngine.invalidateCache();
  }
}
