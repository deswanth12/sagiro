import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/rag/rag_service.dart';
import 'package:sagiro/rag/intent_classifier.dart';
import 'package:sagiro/rag/context_builder.dart';
import 'package:sagiro/rag/financial_ai_engine.dart';
import 'package:sagiro/models/transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RAG Conversational Engine Unit Tests', () {
    test('MoneyBrainResult holds query results cleanly', () {
      final res = MoneyBrainResult(
        intent: FinancialIntent.category,
        response: FormattedMoneyBrainResponse(
          answer: 'Food and Dining is your highest category.',
          reason: 'Frequent dining transactions',
          evidence: 'Swiggy ₹450, Zomato ₹600',
          suggestedAction: 'Set food budget limit',
          followUpQuestions: ['How to save on food?'],
        ),
        contextPayload: ContextPayload(
          formattedContext: 'Food spending: ₹1,050',
          retrievedDocs: const [],
        ),
      );

      expect(res.intent, equals(FinancialIntent.category));
      expect(res.response.answer, contains('Food'));
    });

    test('1. "Are you AI?" answers naturally without data retrieval', () {
      final engine = FinancialAiEngine();
      final res = engine.analyze(
        query: 'Are you AI?',
        intent: IntentClassifier.classify('Are you AI?'),
        contextPayload: ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: const [],
        subscriptions: const [],
        monthlyBudget: 0,
      );

      expect(res.answer, contains('Yep 😄 I’m the AI behind Sagiro.'));
      expect(res.answer, contains('Ask me anything about your spending or budget'));
    });

    test('2. "What’s your name?" / "Who are you?" answers as Sagiro', () {
      final engine = FinancialAiEngine();
      final res = engine.analyze(
        query: "What's your name?",
        intent: IntentClassifier.classify("What's your name?"),
        contextPayload: ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: const [],
        subscriptions: const [],
        monthlyBudget: 0,
      );

      expect(res.answer, contains('I’m Sagiro 👋 Your personal AI finance assistant.'));
    });

    test('3. "Who made you?" describes the Sagiro team with on-device privacy', () {
      final engine = FinancialAiEngine();
      final res = engine.analyze(
        query: 'Who made you?',
        intent: IntentClassifier.classify('Who made you?'),
        contextPayload: ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: const [],
        subscriptions: const [],
        monthlyBudget: 0,
      );

      expect(res.answer, contains('built by the Sagiro team'));
      expect(res.answer, contains('100% on your device'));
    });

    test('4. "Thank you" gives a warm conversational response', () {
      final engine = FinancialAiEngine();
      final res = engine.analyze(
        query: 'Thank you',
        intent: IntentClassifier.classify('Thank you'),
        contextPayload: ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: const [],
        subscriptions: const [],
        monthlyBudget: 0,
      );

      expect(res.answer, contains('You’re welcome! 😊'));
    });

    test('5. "What can you do?" lists key assistant capabilities', () {
      final engine = FinancialAiEngine();
      final res = engine.analyze(
        query: 'What can you do?',
        intent: IntentClassifier.classify('What can you do?'),
        contextPayload: ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: const [],
        subscriptions: const [],
        monthlyBudget: 0,
      );

      expect(res.answer, contains('Here’s what I can do:'));
      expect(res.answer, contains('Track category spending'));
      expect(res.answer, contains('Safe Today'));
    });

    test('6. "Where did my money go?" retrieves and calculates financial analytics', () {
      final engine = FinancialAiEngine();
      final now = DateTime.now();
      final txs = [
        TransactionItem(
          amount: 2500,
          merchant: 'Amazon Shopping',
          category: 'Shopping',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
        TransactionItem(
          amount: 600,
          merchant: 'Swiggy',
          category: 'Food',
          type: TransactionType.debit,
          source: TransactionSource.sms,
          date: now,
          profileId: 'default_profile',
        ),
      ];

      final res = engine.analyze(
        query: 'Where did my money go?',
        intent: IntentClassifier.classify('Where did my money go?'),
        contextPayload: ContextPayload(formattedContext: '', retrievedDocs: const []),
        allTransactions: txs,
        subscriptions: const [],
        monthlyBudget: 0,
      );

      expect(res.answer, contains('Amazon Shopping'));
      expect(res.answer, contains('₹2,500'));
      expect(res.answer, contains('Top spending categories'));
    });
  });
}
