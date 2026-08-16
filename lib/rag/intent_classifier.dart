enum FinancialIntent {
  greeting,
  privacy,
  budget,
  category,
  merchant,
  spendingByCategory,
  spendingByMerchant,
  spendingByTimeframe,
  highestExpense,
  topSpending,
  savings,
  income,
  subscription,
  advice,
  appNavigation,
  appInfo,
  generalEducation,
  forecast,
  timeline,
  bills,
  search,
  comparison,
  analytics,
  family,
  unknown,
}

class IntentClassifier {
  static const List<String> _categoryKeywords = [
    'food',
    'dining',
    'restaurant',
    'swiggy',
    'zomato',
    'eating',
    'groceries',
    'grocery',
    'shopping',
    'clothes',
    'electronics',
    'amazon',
    'flipkart',
    'myntra',
    'fuel',
    'petrol',
    'diesel',
    'gas',
    'travel',
    'transport',
    'cab',
    'taxi',
    'uber',
    'ola',
    'rapido',
    'flight',
    'train',
    'irctc',
    'bills',
    'electricity',
    'water',
    'recharge',
    'wifi',
    'internet',
    'utility',
    'entertainment',
    'movies',
    'ott',
    'netflix',
    'spotify',
    'hotstar',
    'medical',
    'health',
    'pharmacy',
    'doctor',
    'medicine',
    'apollo',
    'investments',
    'stocks',
    'mutual fund',
    'zerodha',
    'groww',
    'salary',
  ];

  static const List<String> _merchantKeywords = [
    'swiggy',
    'zomato',
    'amazon',
    'flipkart',
    'myntra',
    'blinkit',
    'zepto',
    'instamart',
    'uber',
    'ola',
    'rapido',
    'netflix',
    'spotify',
    'hotstar',
    'youtube',
    'google',
    'apple',
    'airtel',
    'jio',
    'vi',
    'starbucks',
    'mcdonalds',
    'kfc',
    'dominos',
    'pizza hut',
    'bookmyshow',
    'irctc',
    'makemytrip',
    'goibibo',
    'apollo',
    'pharmeasy',
    '1mg',
    'tata 1mg',
    'zerodha',
    'groww',
    'upstox',
    'croma',
    'reliance digital',
    'decathlon',
    'dmart',
    'bigbasket',
  ];

  static bool hasCategoryKeyword(String cleanQuery) {
    return _categoryKeywords.any((k) => cleanQuery.contains(k));
  }

  static bool hasMerchantKeyword(String cleanQuery) {
    return _merchantKeywords.any((m) => cleanQuery.contains(m));
  }

  static FinancialIntent classify(String query) {
    final clean = query.toLowerCase().trim();

    // 1. Casual Greeting & Conversational Meta
    if (clean == 'hi' ||
        clean == 'hello' ||
        clean == 'hey' ||
        clean.startsWith('hi ') ||
        clean.startsWith('hello ') ||
        clean.startsWith('hey ') ||
        clean.contains('good morning') ||
        clean.contains('good evening') ||
        clean.contains('good afternoon') ||
        clean == 'thanks' ||
        clean == 'thank you' ||
        clean.startsWith('thank you') ||
        clean.startsWith('thanks') ||
        clean == 'thx' ||
        clean == 'bye' ||
        clean.contains('are you ai') ||
        clean.contains('are you an ai') ||
        clean == 'is this ai' ||
        clean.contains('who are you') ||
        clean.contains('your name') ||
        clean.contains('who made you') ||
        clean.contains('who created you') ||
        clean.contains('who built you') ||
        clean.contains('what can you do') ||
        clean.contains('how can you help')) {
      return FinancialIntent.greeting;
    }

    // 2. Family / Shared Household Intent
    if (clean.contains('family') ||
        clean.contains('household') ||
        clean.contains('our spend') ||
        clean.contains('our expense') ||
        clean.contains('shared expense') ||
        clean.contains('shared spend') ||
        clean.contains('wife') ||
        clean.contains('spouse') ||
        clean.contains('child') ||
        clean.contains('member')) {
      return FinancialIntent.family;
    }

    // 3. Privacy & Security
    if (clean.contains('privacy') ||
        clean.contains('security') ||
        clean.contains('policy') ||
        clean.contains('data safe') ||
        clean.contains('sell data') ||
        clean.contains('vault safe')) {
      return FinancialIntent.privacy;
    }

    // 3. Highest / Largest / Biggest Expense / Top Spending
    if (clean.contains('highest expense') ||
        clean.contains('biggest expense') ||
        clean.contains('largest expense') ||
        clean.contains('biggest purchase') ||
        clean.contains('largest purchase') ||
        clean.contains('highest purchase') ||
        clean.contains('what was my highest') ||
        clean.contains('what was my biggest') ||
        clean.contains('where did i spend the most') ||
        clean.contains('where did i spend most') ||
        clean.contains('where did my money go') ||
        clean.contains('where did my money went') ||
        clean.contains('where my money go') ||
        clean.contains('where my money went') ||
        clean.contains('what are my biggest expenses') ||
        clean.contains('top expenses') ||
        clean.contains('top spending') ||
        clean.contains('max expense') ||
        clean.contains('where i spend most') ||
        clean.contains('where i spend the most')) {
      return FinancialIntent.highestExpense;
    }

    // 4. Budget & Safe Today & Remaining Balance
    if (clean.contains('how much money do i have left') ||
        clean.contains('money left from my budget') ||
        clean.contains('money left') ||
        clean.contains('budget left') ||
        clean.contains('remaining budget') ||
        clean.contains('safe today') ||
        clean.contains('daily safe limit') ||
        clean.contains('safe limit') ||
        clean.contains('daily limit') ||
        clean.contains('can i afford') ||
        clean.contains('safe to spend') ||
        clean.contains('my budget')) {
      return FinancialIntent.budget;
    }

    // 5. Savings / Goals
    if (clean.contains('how much did i save') ||
        clean.contains('how much have i saved') ||
        clean.contains('how much saved') ||
        clean.contains('my savings') ||
        clean.contains('savings goal') ||
        clean.contains('emergency fund')) {
      return FinancialIntent.savings;
    }

    // 6. Income / Salary
    if (clean.contains('income') ||
        clean.contains('salary') ||
        clean.contains('how much earned') ||
        clean.contains('credited') ||
        clean.contains('how much did i earn')) {
      return FinancialIntent.income;
    }

    // 7. Subscriptions
    if (clean.contains('subscription') ||
        clean.contains('recurring') ||
        clean.contains('cancel subscription')) {
      return FinancialIntent.subscription;
    }

    // 8. Discretionary / Advice
    if (clean.contains('wasting money') ||
        clean.contains('where am i wasting') ||
        clean.contains('spending leak') ||
        clean.contains('why am i broke')) {
      return FinancialIntent.advice;
    }

    // 9. Category Spending Queries ("how much i spend the food", "how much did i spend on food", "show my food expenses")
    if (hasCategoryKeyword(clean)) {
      return FinancialIntent.spendingByCategory;
    }

    // 10. Merchant Spending Queries ("how much did i spend on Swiggy", "Swiggy expenses")
    if (hasMerchantKeyword(clean)) {
      return FinancialIntent.spendingByMerchant;
    }

    // 11. Timeframe Specific Queries ("what did i spend yesterday", "how much did i spend this month", "this week spend")
    if (clean.contains('yesterday') ||
        clean.contains('today') ||
        clean.contains('this week') ||
        clean.contains('last week') ||
        clean.contains('this month') ||
        clean.contains('last month') ||
        clean.contains('past 7 days') ||
        clean.contains('past 30 days') ||
        clean.contains('all time') ||
        clean.contains('spend') ||
        clean.contains('spent') ||
        clean.contains('spending') ||
        clean.contains('expense') ||
        clean.contains('expenses') ||
        clean.contains('purchases') ||
        clean.contains('cost') ||
        clean.contains('paid')) {
      return FinancialIntent.spendingByTimeframe;
    }

    // 12. App Navigation
    if (clean.startsWith('where') ||
        clean.startsWith('how do i add') ||
        clean.startsWith('how to add') ||
        clean.startsWith('how do i create') ||
        clean.startsWith('how to create') ||
        clean.contains('how do i find') ||
        clean.contains('where are my') ||
        clean.contains('where can i') ||
        clean.contains('where to find') ||
        clean.contains('how to import') ||
        clean.contains('import statement') ||
        clean.contains('private sync')) {
      return FinancialIntent.appNavigation;
    }

    // 13. General Financial Education
    if (clean.contains('what is sip') ||
        clean.contains('compound interest') ||
        clean.contains('emergency fund') ||
        clean.contains('50-30-20') ||
        clean.contains('mutual fund')) {
      return FinancialIntent.generalEducation;
    }

    return FinancialIntent.appInfo;
  }
}

enum GuideIntentCategory {
  casual,
  appInfo,
  appNavigation,
  financialGuidance,
  dataQuery,
  actionRequest,
  unknown,
}

class GuideIntentClassifier {
  static GuideIntentCategory classify(String query) {
    final clean = query.toLowerCase().trim();

    // 1. Casual Conversation Intent
    if (clean == 'hi' ||
        clean == 'hello' ||
        clean == 'hey' ||
        clean == 'thanks' ||
        clean == 'thank you' ||
        clean == 'good morning' ||
        clean == 'good afternoon' ||
        clean == 'good evening' ||
        clean == 'bye' ||
        clean == 'who are you' ||
        clean.startsWith('hi ') ||
        clean.startsWith('hello ') ||
        clean.startsWith('hey ')) {
      return GuideIntentCategory.casual;
    }

    // 2. Action Request / Destructive Intent
    if (clean.contains('delete') ||
        clean.contains('remove') ||
        clean.contains('clear data') ||
        clean.contains('reset')) {
      return GuideIntentCategory.actionRequest;
    }

    // 3. App Info Intent ("What is Safe Today?", "What is Vault?", "What are Fixed Expenses?")
    if (clean.startsWith('what is ') ||
        clean.startsWith('what are ') ||
        clean.startsWith('what does ') ||
        clean.startsWith('how does ') ||
        clean.contains('what are fixed expenses') ||
        clean.contains('what is pro') ||
        clean.contains('how does backup work') ||
        clean.contains('how does sms work') ||
        clean.contains('what is vault')) {
      return GuideIntentCategory.appInfo;
    }

    // 4. App Navigation Intent
    if (clean.startsWith('where is') ||
        clean.startsWith('where are') ||
        clean.startsWith('where can') ||
        clean.startsWith('where to') ||
        clean.startsWith('how do i add') ||
        clean.startsWith('how to add') ||
        clean.startsWith('how do i create') ||
        clean.startsWith('how to create') ||
        clean.contains('how do i find') ||
        clean.contains('where are my') ||
        clean.contains('where can i') ||
        clean.contains('where to find') ||
        clean.contains('how to import')) {
      return GuideIntentCategory.appNavigation;
    }

    // 5. Off-Topic / Unknown Questions
    if (clean.contains('cricket') ||
        clean.contains('weather') ||
        clean.contains('movie') ||
        clean.contains('president') ||
        clean.contains('score') ||
        clean.contains('news')) {
      return GuideIntentCategory.unknown;
    }

    // 6. Financial Data Query (Spending, Categories, Merchants, Timeframes, Amounts)
    if (clean.contains('spend') ||
        clean.contains('spent') ||
        clean.contains('spending') ||
        clean.contains('expense') ||
        clean.contains('expenses') ||
        clean.contains('food') ||
        clean.contains('shopping') ||
        clean.contains('fuel') ||
        clean.contains('travel') ||
        clean.contains('bills') ||
        clean.contains('swiggy') ||
        clean.contains('zomato') ||
        clean.contains('amazon') ||
        clean.contains('yesterday') ||
        clean.contains('today') ||
        clean.contains('this month') ||
        clean.contains('last month') ||
        clean.contains('this week') ||
        clean.contains('biggest') ||
        clean.contains('highest') ||
        clean.contains('balance') ||
        clean.contains('budget') ||
        clean.contains('safe today') ||
        clean.contains('save')) {
      return GuideIntentCategory.dataQuery;
    }

    return GuideIntentCategory.dataQuery;
  }
}
