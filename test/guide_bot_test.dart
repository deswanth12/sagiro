import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/rag/intent_classifier.dart';
import 'package:sagiro/rag/sagiro_knowledge_base.dart';
import 'package:sagiro/rag/sagiro_guide_engine.dart';
import 'package:sagiro/providers/budget_provider.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  group('Sagiro Guide Bot Comprehensive Unit Tests', () {
    test('1. Casual greetings return friendly conversational responses', () {
      final resHi = SagiroGuideEngine.processQuery(query: 'Hi');
      expect(resHi.category, equals(GuideIntentCategory.casual));
      expect(resHi.text, contains('Sagiro Guide'));

      final resHello = SagiroGuideEngine.processQuery(query: 'Hello');
      expect(resHello.category, equals(GuideIntentCategory.casual));
      expect(resHello.text, contains('help you with Sagiro'));

      final resMorning = SagiroGuideEngine.processQuery(query: 'Good morning');
      expect(resMorning.category, equals(GuideIntentCategory.casual));
      expect(resMorning.text, contains('Good morning'));

      final resThanks = SagiroGuideEngine.processQuery(query: 'Thanks');
      expect(resThanks.category, equals(GuideIntentCategory.casual));
      expect(resThanks.text, equals('Anytime! 😊'));
    });

    test('2. App information questions return grounded feature descriptions',
        () {
      final resSafeToday =
          SagiroGuideEngine.processQuery(query: 'What is Safe Today?');
      expect(resSafeToday.category, equals(GuideIntentCategory.appInfo));
      expect(resSafeToday.text,
          equals(SagiroKnowledgeBase.features['safe_today']));

      final resVault = SagiroGuideEngine.processQuery(query: 'What is Vault?');
      expect(resVault.category, equals(GuideIntentCategory.appInfo));
      expect(resVault.text, equals(SagiroKnowledgeBase.features['vault']));

      final resFixed =
          SagiroGuideEngine.processQuery(query: 'What are Fixed Expenses?');
      expect(resFixed.category, equals(GuideIntentCategory.appInfo));
      expect(resFixed.text,
          equals(SagiroKnowledgeBase.features['fixed_expenses']));
    });

    test('3. App navigation questions return short actionable steps', () {
      final resExp =
          SagiroGuideEngine.processQuery(query: 'Where are my expenses?');
      expect(resExp.category, equals(GuideIntentCategory.appNavigation));
      expect(resExp.text, contains('Open Timeline'));

      final resAddGoal =
          SagiroGuideEngine.processQuery(query: 'How do I add a goal?');
      expect(resAddGoal.category, equals(GuideIntentCategory.appNavigation));
      expect(resAddGoal.text, contains('Open Goals → Add Goal'));

      final resRecurring = SagiroGuideEngine.processQuery(
          query: 'Where can I manage recurring expenses?');
      expect(resRecurring.category, equals(GuideIntentCategory.appNavigation));
      expect(resRecurring.text, contains('Open Budget → Fixed Expenses'));

      final resBackup =
          SagiroGuideEngine.processQuery(query: 'Where are my backups?');
      expect(resBackup.category, equals(GuideIntentCategory.appNavigation));
      expect(resBackup.text, contains('Open Vault → Backup'));
    });

    test('4. Data queries query actual provider data without hallucination',
        () {
      final provider = BudgetProvider();
      provider.updateMonthlyBudget(25000.0);

      final resSpendToday = SagiroGuideEngine.processQuery(
        query: 'How much can I spend today?',
        budgetProvider: provider,
      );
      expect(resSpendToday.category, equals(GuideIntentCategory.dataQuery));
      expect(resSpendToday.text, contains('Safe Today spending limit'));

      final resFood = SagiroGuideEngine.processQuery(
        query: 'How much did I spend on food?',
        budgetProvider: provider,
      );
      expect(resFood.category, equals(GuideIntentCategory.dataQuery));
      expect(resFood.text, contains('food expenses'));
    });

    test('5. Unknown questions return friendly off-topic boundary response',
        () {
      final resCricket = SagiroGuideEngine.processQuery(
          query: 'Who won yesterday\'s cricket match?');
      expect(resCricket.category, equals(GuideIntentCategory.unknown));
      expect(resCricket.text, contains('mainly here to help with Sagiro'));
    });

    test('6. Destructive action requests require explicit confirmation', () {
      final resDelete = SagiroGuideEngine.processQuery(query: 'Delete my goal');
      expect(resDelete.category, equals(GuideIntentCategory.actionRequest));
      expect(resDelete.text, contains('Which goal would you like to delete?'));

      final resDeleteLaptop =
          SagiroGuideEngine.processQuery(query: 'Delete Laptop goal');
      expect(
          resDeleteLaptop.category, equals(GuideIntentCategory.actionRequest));
      expect(resDeleteLaptop.text, contains('cannot be undone'));
    });

    test('7. Context awareness resolves follow-up questions', () {
      final resFollowUp = SagiroGuideEngine.processQuery(
        query: 'Why is mine low?',
        messageHistory: ['What is Safe Today?'],
      );
      expect(
          resFollowUp.category, equals(GuideIntentCategory.financialGuidance));
      expect(resFollowUp.text, contains('Safe Today amount can fall'));
    });
  });
}
