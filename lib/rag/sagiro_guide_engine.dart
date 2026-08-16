import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import 'intent_classifier.dart';
import 'sagiro_knowledge_base.dart';

class GuideResponse {
  final String text;
  final GuideIntentCategory category;
  final String? suggestedActionLabel;
  final String? suggestedActionRoute;

  GuideResponse({
    required this.text,
    required this.category,
    this.suggestedActionLabel,
    this.suggestedActionRoute,
  });
}

class SagiroGuideEngine {
  static final currency =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  static GuideResponse processQuery({
    required String query,
    BudgetProvider? budgetProvider,
    List<String> messageHistory = const [],
  }) {
    final clean = query.toLowerCase().trim();
    final category = GuideIntentClassifier.classify(query);

    // 1. CASUAL CONVERSATION (Instant Deterministic Response)
    if (category == GuideIntentCategory.casual) {
      if (clean == 'hi') {
        return GuideResponse(
          text: 'Hey! 👋 I’m Sagiro Guide. What would you like help with?',
          category: category,
        );
      }
      if (clean == 'hello') {
        return GuideResponse(
          text: 'Hey! How can I help you with Sagiro today?',
          category: category,
        );
      }
      if (clean.contains('good morning')) {
        return GuideResponse(
          text: 'Good morning! What would you like to check?',
          category: category,
        );
      }
      if (clean.contains('thanks') || clean.contains('thank you')) {
        return GuideResponse(
          text: 'Anytime! 😊',
          category: category,
        );
      }
      if (clean == 'bye') {
        return GuideResponse(
          text: 'Goodbye! Have a great day ahead. 😊',
          category: category,
        );
      }
      return GuideResponse(
        text:
            'I’m Sagiro Guide, your in-app assistant for managing your money and Sagiro features.',
        category: category,
      );
    }

    // 2. UNKNOWN / OFF-TOPIC QUESTIONS
    if (category == GuideIntentCategory.unknown) {
      return GuideResponse(
        text:
            'I’m mainly here to help with Sagiro and your finances. Ask me anything about your expenses, budgets, goals, or the app.',
        category: category,
      );
    }

    // 3. ACTION REQUEST (Destructive Action Guards)
    if (category == GuideIntentCategory.actionRequest) {
      if (clean.contains('delete') && clean.contains('goal')) {
        if (clean.contains('laptop') || clean.contains('emergency')) {
          return GuideResponse(
            text:
                'Delete this goal? This cannot be undone. You can confirm deletion inside Goals.',
            category: category,
            suggestedActionLabel: 'Open Goals',
            suggestedActionRoute: 'goals',
          );
        }
        return GuideResponse(
          text:
              'Which goal would you like to delete? Open Goals to manage your savings targets.',
          category: category,
          suggestedActionLabel: 'Open Goals',
          suggestedActionRoute: 'goals',
        );
      }
      if (clean.contains('clear data') || clean.contains('reset')) {
        return GuideResponse(
          text:
              'Clear all financial data? This will remove all transactions and settings. Confirm in Vault → Settings.',
          category: category,
          suggestedActionLabel: 'Open Vault',
          suggestedActionRoute: 'vault',
        );
      }
    }

    // 4. APP NAVIGATION ("Where are my expenses?", "Where can I manage recurring expenses?")
    if (category == GuideIntentCategory.appNavigation) {
      if (clean.contains('recurring') || clean.contains('fixed')) {
        return GuideResponse(
          text: 'Open Budget → Fixed Expenses.',
          category: category,
          suggestedActionLabel: 'Open Budget',
          suggestedActionRoute: 'budget',
        );
      }
      if (clean.contains('goal')) {
        return GuideResponse(
          text: 'Open Goals → Add Goal.',
          category: category,
          suggestedActionLabel: 'Open Goals',
          suggestedActionRoute: 'goals',
        );
      }
      if (clean.contains('backup') || clean.contains('restore')) {
        return GuideResponse(
          text: 'Open Vault → Backup.',
          category: category,
          suggestedActionLabel: 'Open Vault',
          suggestedActionRoute: 'vault',
        );
      }
      if (clean.contains('expense') || clean.contains('transaction')) {
        return GuideResponse(
          text: 'Open Timeline to view your transactions.',
          category: category,
          suggestedActionLabel: 'Open Timeline',
          suggestedActionRoute: 'timeline',
        );
      }
      if (clean.contains('account')) {
        return GuideResponse(
          text: 'Open Accounts overview from the Dashboard.',
          category: category,
          suggestedActionLabel: 'Open Dashboard',
          suggestedActionRoute: 'dashboard',
        );
      }
      return GuideResponse(
        text: 'You can navigate using the main navigation tabs at the bottom.',
        category: category,
      );
    }

    // 5. APP INFORMATION ("What is Safe Today?", "What are Fixed Expenses?")
    if (category == GuideIntentCategory.appInfo) {
      if (clean.contains('safe today')) {
        return GuideResponse(
          text: SagiroKnowledgeBase.features['safe_today']!,
          category: category,
        );
      }
      if (clean.contains('timeline')) {
        return GuideResponse(
          text: SagiroKnowledgeBase.features['timeline']!,
          category: category,
        );
      }
      if (clean.contains('fixed expense') || clean.contains('recurring')) {
        return GuideResponse(
          text: SagiroKnowledgeBase.features['fixed_expenses']!,
          category: category,
        );
      }
      if (clean.contains('vault') || clean.contains('security')) {
        return GuideResponse(
          text: SagiroKnowledgeBase.features['vault']!,
          category: category,
        );
      }
      if (clean.contains('backup')) {
        return GuideResponse(
          text:
              'Backups are created as encrypted .ppbackup files in Vault. You can restore them anytime on any device.',
          category: category,
        );
      }
      if (clean.contains('pro')) {
        return GuideResponse(
          text: SagiroKnowledgeBase.features['pro']!,
          category: category,
        );
      }
      if (clean.contains('sms')) {
        return GuideResponse(
          text: SagiroKnowledgeBase.features['sms_detection']!,
          category: category,
        );
      }
      return GuideResponse(
        text:
            'Sagiro is a privacy-first personal finance app that helps you track expenses, manage budgets, and know what’s safe to spend today.',
        category: category,
      );
    }

    // 6. DATA QUERY & FINANCIAL GUIDANCE (Uses Actual Sagiro Data)
    if (budgetProvider != null) {
      if (clean.contains('spend today') ||
          clean.contains('safe today amount')) {
        final safeToday = budgetProvider.dailySafeSpendingLimit;
        return GuideResponse(
          text:
              'Your Safe Today spending limit is ${currency.format(safeToday)} today.',
          category: GuideIntentCategory.dataQuery,
        );
      }

      if (clean.contains('food')) {
        final foodSpend = budgetProvider.categoryBreakdown['Food'] ?? 0.0;
        if (foodSpend == 0.0) {
          return GuideResponse(
            text: 'You haven’t recorded any food expenses this month.',
            category: GuideIntentCategory.dataQuery,
          );
        }
        return GuideResponse(
          text:
              'You have spent ${currency.format(foodSpend)} on food this month.',
          category: GuideIntentCategory.dataQuery,
        );
      }

      if (clean.contains('month spend') || clean.contains('spent this month')) {
        final monthSpend = budgetProvider.monthSpend;
        return GuideResponse(
          text:
              'You have spent ${currency.format(monthSpend)} of your ${currency.format(budgetProvider.monthlyBudget)} budget so far this month.',
          category: GuideIntentCategory.dataQuery,
        );
      }
    }

    // 7. Context-Aware Follow-Up Resolution ("Why is mine low?")
    final lastQuery =
        messageHistory.isNotEmpty ? messageHistory.last.toLowerCase() : '';
    if (clean.contains('why is mine low') ||
        clean.contains('why did it drop')) {
      if (lastQuery.contains('safe today') ||
          lastQuery.contains('spend today')) {
        return GuideResponse(
          text:
              'Your Safe Today amount can fall when upcoming fixed expenses, recent spending, or fewer remaining days reduce your available money.',
          category: GuideIntentCategory.financialGuidance,
        );
      }
    }

    return GuideResponse(
      text:
          'Sagiro Guide is here to help. Ask me about your expenses, budgets, fixed expenses, or how to use the app!',
      category: category,
    );
  }
}
