import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/subscription.dart';
import 'intent_classifier.dart';
import 'context_builder.dart';
import '../utils/month_range.dart';

class FormattedMoneyBrainResponse {
  final String answer;
  final String reason;
  final String evidence;
  final String suggestedAction;
  final List<String> followUpQuestions;

  FormattedMoneyBrainResponse({
    required this.answer,
    required this.reason,
    required this.evidence,
    required this.suggestedAction,
    required this.followUpQuestions,
  });

  /// Natural Conversational Formatting — Warm, intelligent, human-centric.
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln(answer);
    if (suggestedAction.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(suggestedAction);
    }
    return buffer.toString().trim();
  }
}

class FinancialAiEngine {
  static int _revision = 0;
  static final Map<String, FormattedMoneyBrainResponse> _queryResponseCache =
      {};

  /// Invalidate Money Brain cache on transaction mutations, imports, restores, or profile switches
  static void invalidateCache() {
    _revision++;
    _queryResponseCache.clear();
  }

  /// Explicitly bump dataset revision version
  static void bumpRevision() {
    _revision++;
  }

  FormattedMoneyBrainResponse analyze({
    required String query,
    required FinancialIntent intent,
    required ContextPayload contextPayload,
    required List<TransactionItem> allTransactions,
    required List<SubscriptionItem> subscriptions,
    required double monthlyBudget,
  }) {
    final cleanQuery = query.toLowerCase().trim();
    final now = DateTime.now();

    final String activeProfileId = allTransactions.isNotEmpty
        ? allTransactions.first.profileId
        : 'default_profile';
    final cacheKey = '${activeProfileId}_rev_${_revision}_$cleanQuery';

    if (_queryResponseCache.containsKey(cacheKey)) {
      return _queryResponseCache[cacheKey]!;
    }

    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    // 0. Privacy & Security Policy Intent
    if (intent == FinancialIntent.privacy ||
        cleanQuery.contains('privacy') ||
        cleanQuery.contains('policy') ||
        cleanQuery.contains('data safe') ||
        cleanQuery.contains('sell data') ||
        cleanQuery.contains('security')) {
      final res = FormattedMoneyBrainResponse(
        answer:
            'Your financial data stays 100% on your device. Everything is encrypted locally, and your numbers never touch any intermediate servers.',
        reason: '',
        evidence: '',
        suggestedAction:
            'You can check or export your encrypted backup anytime from the Vault in Settings.',
        followUpQuestions: const [
          'How does Private Sync work?',
          'What is Safe Today™?',
          'How much have I spent this month?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.1 Casual AI Identity Query ("Are you AI?", "Are you real?", "Are you a bot?")
    if (cleanQuery.contains('are you ai') ||
        cleanQuery.contains('are you an ai') ||
        cleanQuery == 'is this ai' ||
        cleanQuery.contains('are you a bot') ||
        cleanQuery.contains('are you a robot') ||
        cleanQuery.contains('are you real') ||
        cleanQuery.contains('are you human')) {
      final res = FormattedMoneyBrainResponse(
        answer:
            'Yep 😄 I’m the AI behind Sagiro. Ask me anything about your spending or budget, and I’ll help you make sense of it.',
        reason: '',
        evidence: '',
        suggestedAction: '',
        followUpQuestions: const [
          'How much have I spent this month?',
          'Where did most of my money go?',
          'How much can I safely spend today?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.2 Name / Identity Query ("What's your name?", "Who are you?")
    if (cleanQuery == 'who are you' ||
        cleanQuery == 'what is your name' ||
        cleanQuery == "what's your name" ||
        cleanQuery == 'whats your name' ||
        cleanQuery.contains('what is your name') ||
        cleanQuery.contains("what's your name") ||
        cleanQuery.contains('whats your name') ||
        cleanQuery.contains('your name')) {
      final res = FormattedMoneyBrainResponse(
        answer: 'I’m Sagiro 👋 Your personal AI finance assistant.',
        reason: '',
        evidence: '',
        suggestedAction: 'Ask me anything about your spending, budget, or daily limits.',
        followUpQuestions: const [
          'What can you do?',
          'How much have I spent this month?',
          'Where did most of my money go?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.3 Origin / Maker Query ("Who made you?", "Who built you?")
    if (cleanQuery.contains('who made you') ||
        cleanQuery.contains('who created you') ||
        cleanQuery.contains('who built you') ||
        cleanQuery.contains('who developed you') ||
        cleanQuery.contains('who made sagiro') ||
        cleanQuery.contains('who built sagiro')) {
      final res = FormattedMoneyBrainResponse(
        answer:
            'I was built by the Sagiro team to give you a private, intelligent money assistant that operates 100% on your device.',
        reason: '',
        evidence: '',
        suggestedAction: 'Your financial data stays locally encrypted on your phone.',
        followUpQuestions: const [
          'Is my data private?',
          'What can you do?',
          'How much can I safely spend today?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.4 Gratitude Query ("Thank you", "Thanks", "Thx")
    if (cleanQuery == 'thanks' ||
        cleanQuery == 'thank you' ||
        cleanQuery.startsWith('thank you') ||
        cleanQuery.startsWith('thanks') ||
        cleanQuery == 'thx' ||
        cleanQuery.contains('thank u')) {
      final res = FormattedMoneyBrainResponse(
        answer:
            'You’re welcome! 😊 Let me know whenever you want to check your spending, daily limits, or budget.',
        reason: '',
        evidence: '',
        suggestedAction: '',
        followUpQuestions: const [
          'How much have I spent this month?',
          'Where did most of my money go?',
          'How much can I safely spend today?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.5 Capabilities Query ("What can you do?", "Help")
    if (cleanQuery.contains('what can you do') ||
        cleanQuery.contains('what do you do') ||
        cleanQuery.contains('how can you help') ||
        cleanQuery == 'help' ||
        cleanQuery.contains('what are your capabilities') ||
        cleanQuery.contains('what are your features')) {
      final res = FormattedMoneyBrainResponse(
        answer:
            'I help you understand where your money is going with on-device intelligence. Here’s what I can do:\n\n• Track category spending (e.g., “How much did I spend on food?”)\n• Check merchant totals (e.g., “How much on Swiggy?”)\n• Find biggest expenses (“Where did most of my money go?”)\n• Calculate Safe Today daily limit (“How much can I safely spend today?”)\n• Review monthly summaries (“How much have I spent this month?”)',
        reason: '',
        evidence: '',
        suggestedAction: 'Ask me anything about your finances!',
        followUpQuestions: const [
          'How much have I spent this month?',
          'Where did most of my money go?',
          'How much can I safely spend today?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.6 Warm Greeting Intent ("Hi", "Hello", "Hey")
    if (intent == FinancialIntent.greeting ||
        cleanQuery == 'hi' ||
        cleanQuery == 'hello' ||
        cleanQuery == 'hey' ||
        cleanQuery.startsWith('hi ') ||
        cleanQuery.startsWith('hello ') ||
        cleanQuery.startsWith('hey ') ||
        cleanQuery.contains('good morning') ||
        cleanQuery.contains('good evening') ||
        cleanQuery.contains('good afternoon')) {
      final hasData = allTransactions.isNotEmpty;
      final res = FormattedMoneyBrainResponse(
        answer: hasData
            ? 'Hey! 👋\nI’ve got your finances ready.\n\nWant to see where your money went, check your budget, or find out how much you can spend today?'
            : 'Hi, I’m Sagiro 👋\nI’m here to help you understand where your money is going.\n\nAsk me anything about your spending, budgets, savings, or accounts.\n\nFor example:\n• “How much have I spent this month?”\n• “Where did most of my money go?”\n• “Am I spending too much on food?”\n• “How much can I safely spend today?”\n\nWhat do you want to check?',
        reason: '',
        evidence: '',
        suggestedAction: '',
        followUpQuestions: const [
          'How much have I spent this month?',
          'Where did most of my money go?',
          'Am I spending too much on food?',
          'How much can I safely spend today?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.2 Family / Household Spending Intent
    if (intent == FinancialIntent.family ||
        cleanQuery.contains('family') ||
        cleanQuery.contains('household') ||
        cleanQuery.contains('shared spend') ||
        cleanQuery.contains('shared expense') ||
        cleanQuery.contains('our spend') ||
        cleanQuery.contains('our expense')) {
      final sharedTxs = allTransactions.where((t) => t.isShared).toList();
      final sharedDebits =
          sharedTxs.where((t) => t.type == TransactionType.debit).toList();
      final totalShared =
          sharedDebits.fold<double>(0, (sum, t) => sum + t.amount);

      if (sharedDebits.isEmpty) {
        final res = FormattedMoneyBrainResponse(
          answer: 'Your household currently has ₹0 in shared expenses.',
          reason:
              'Only transactions explicitly toggled as "Share with Family" are visible in the Family Workspace.',
          evidence: '0 shared expense transactions found in this profile.',
          suggestedAction:
              'To share an expense, toggle "Share with Family" when adding or editing a transaction.',
          followUpQuestions: const [
            'How much did I spend this month?',
            'Where did I spend the most?',
            'What is my daily safe spending limit?',
          ],
        );
        _queryResponseCache[cacheKey] = res;
        return res;
      }

      final res = FormattedMoneyBrainResponse(
        answer:
            'Shared Family Expenses: ${currency.format(totalShared)}\n\nFound ${sharedDebits.length} shared transaction${sharedDebits.length != 1 ? 's' : ''}.',
        reason:
            'Family Workspace calculations strictly aggregate only transactions with "Share with Family" enabled to preserve private data isolation.',
        evidence:
            'Aggregated ${sharedDebits.length} shared records totaling ${currency.format(totalShared)}.',
        suggestedAction:
            'Open the Family Workspace screen to view member contributions, shared budgets, and household goals.',
        followUpQuestions: [
          'How much did I spend this month?',
          'Where did I spend the most?',
          'What is my daily safe spending limit?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 0.5 Zero Data Guard (Empty Database)
    if (allTransactions.isEmpty) {
      final res = FormattedMoneyBrainResponse(
        answer: 'No transactions recorded in this profile yet.',
        reason:
            'Money Brain operates 100% on-device using your local bank SMS and financial records.',
        evidence:
            'Your financial vault currently has 0 recorded transactions for this profile.',
        suggestedAction:
            'Tap "Scan SMS" or "Add" on the dashboard to start tracking your finances.',
        followUpQuestions: const [
          'How do I scan SMS?',
          'What is Safe Today™?',
          'Is my data private?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 1. Highest / Largest / Biggest Purchase & "Where did I spend the most?"
    if (intent == FinancialIntent.highestExpense ||
        cleanQuery.contains('biggest') ||
        cleanQuery.contains('highest') ||
        cleanQuery.contains('largest') ||
        cleanQuery.contains('spend the most') ||
        cleanQuery.contains('spend most') ||
        cleanQuery.contains('top expenses') ||
        cleanQuery.contains('top spending')) {
      final debits = allTransactions
          .where((t) => t.type == TransactionType.debit)
          .toList();

      if (debits.isEmpty) {
        final res = FormattedMoneyBrainResponse(
          answer: 'You haven\'t recorded any expenses yet.',
          reason: '',
          evidence: '',
          suggestedAction: 'Once you add or scan transactions, I can show you your biggest expenses.',
          followUpQuestions: const [
            'How much have I spent this month?',
            'How much can I safely spend today?'
          ],
        );
        _queryResponseCache[cacheKey] = res;
        return res;
      }

      final maxTx = debits
          .reduce((curr, next) => next.amount > curr.amount ? next : curr);
      final formattedAmt = currency.format(maxTx.amount);

      // Category breakdown
      final catMap = <String, double>{};
      for (final t in debits) {
        catMap[t.category] = (catMap[t.category] ?? 0.0) + t.amount;
      }
      final sortedCats = catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCat = sortedCats.first;
      final topCatsBuffer = StringBuffer();
      topCatsBuffer.writeln('Top spending categories:');
      for (int i = 0; i < sortedCats.length && i < 3; i++) {
        final entry = sortedCats[i];
        topCatsBuffer.writeln(
            '• ${entry.key}: ${currency.format(entry.value)}');
      }

      final res = FormattedMoneyBrainResponse(
        answer:
            'Your biggest single expense was $formattedAmt at ${maxTx.merchant} on ${DateFormat('d MMMM').format(maxTx.date)}.\n\n${topCatsBuffer.toString().trim()}',
        reason: '',
        evidence: '',
        suggestedAction:
            'Want me to break down your ${topCat.key} spending or check your daily limit?',
        followUpQuestions: const [
          'How much have I spent this month?',
          'How much can I safely spend today?',
          'How much did I spend on food?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 2. Income / Credits / Salary Query
    if (intent == FinancialIntent.income ||
        cleanQuery.contains('income') ||
        cleanQuery.contains('salary') ||
        cleanQuery.contains('credit') ||
        cleanQuery.contains('earned')) {
      final credits = allTransactions
          .where((t) => t.type == TransactionType.credit)
          .toList();
      final totalIncome = credits.fold<double>(0, (sum, t) => sum + t.amount);
      final formattedInc = currency.format(totalIncome);

      final res = FormattedMoneyBrainResponse(
        answer: credits.isNotEmpty
            ? 'You\'ve received $formattedInc in total income so far. Your latest credit was ${currency.format(credits.first.amount)} from ${credits.first.merchant} on ${DateFormat('d MMM').format(credits.first.date)}.'
            : 'No income credits have been recorded yet.',
        reason: '',
        evidence: '',
        suggestedAction:
            'Want to see how much of this you\'ve saved or spent so far?',
        followUpQuestions: const [
          'How much have I spent this month?',
          'How much did I save?',
          'How much can I safely spend today?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 3. Savings / Goals Query
    if (intent == FinancialIntent.savings ||
        cleanQuery.contains('save') ||
        cleanQuery.contains('saved') ||
        cleanQuery.contains('savings')) {
      final credits = allTransactions
          .where((t) => t.type == TransactionType.credit)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final debits = allTransactions
          .where((t) => t.type == TransactionType.debit)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final netSaved = credits - debits;

      final res = FormattedMoneyBrainResponse(
        answer: netSaved > 0
            ? 'You’ve saved ${currency.format(netSaved)} so far (${currency.format(credits)} income − ${currency.format(debits)} spent).'
            : 'You\'ve spent ${currency.format(debits)}, which is currently more than your recorded income (${currency.format(credits)}).',
        reason: '',
        evidence: '',
        suggestedAction:
            'Want to see where most of your expenses went this month?',
        followUpQuestions: const [
          'How much can I safely spend today?',
          'How much have I spent this month?',
          'Where did most of my money go?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 4. Safe Today / Daily Spending / Budget Remaining Intent
    if (intent == FinancialIntent.budget ||
        cleanQuery.contains('safe today') ||
        cleanQuery.contains('daily limit') ||
        cleanQuery.contains('daily safe') ||
        cleanQuery.contains('money left') ||
        cleanQuery.contains('budget left') ||
        cleanQuery.contains('remaining budget') ||
        cleanQuery.contains('can i afford') ||
        cleanQuery.contains('safe to spend')) {
      final currentMonthRange = MonthRange.current();
      final monthSpent = allTransactions.where((t) {
        return currentMonthRange.contains(t.date) &&
            t.type == TransactionType.debit;
      }).fold<double>(0, (sum, t) => sum + t.amount);

      final todaySpent = allTransactions.where((t) {
        final local = t.date.toLocal();
        return local.year == now.year &&
            local.month == now.month &&
            local.day == now.day &&
            t.type == TransactionType.debit;
      }).fold<double>(0, (sum, t) => sum + t.amount);

      final daysRemaining = currentMonthRange.daysRemaining(now);
      final budgetRemaining =
          (monthlyBudget - monthSpent).clamp(0.0, double.infinity);
      final safeDailyLimit = daysRemaining > 0
          ? (budgetRemaining / daysRemaining)
          : budgetRemaining;
      final todayRemaining =
          (safeDailyLimit - todaySpent).clamp(0.0, double.infinity);

      final formattedSafe = currency.format(safeDailyLimit);
      final formattedTodayRem = currency.format(todayRemaining);
      final formattedBudgetRem = currency.format(budgetRemaining);
      final formattedBudget = currency.format(monthlyBudget);

      final res = FormattedMoneyBrainResponse(
        answer: monthlyBudget > 0
            ? 'Your Safe Today™ spending limit is $formattedSafe/day ($formattedTodayRem left for today).\n\n$formattedBudgetRem remaining from your $formattedBudget monthly budget across $daysRemaining days left in ${DateFormat('MMMM').format(now)}.'
            : 'You haven\'t set a monthly budget yet. You’ve spent ${currency.format(monthSpent)} so far in ${DateFormat('MMMM').format(now)} (${currency.format(todaySpent)} spent today).',
        reason: monthlyBudget > 0
            ? 'Calculated from $formattedBudgetRem remaining budget divided by $daysRemaining remaining days in the month.'
            : 'No monthly budget set yet.',
        evidence: monthlyBudget > 0
            ? 'Month budget: $formattedBudget, Month spent: ${currency.format(monthSpent)}, Today spent: ${currency.format(todaySpent)}.'
            : 'Month spent: ${currency.format(monthSpent)}.',
        suggestedAction: monthlyBudget > 0
            ? (todaySpent > safeDailyLimit
                ? 'You\'re slightly ahead of today\'s pace. Taking it easy tomorrow will keep your monthly budget balanced.'
                : 'Staying under $formattedSafe today keeps your budget right on track.')
            : 'Setting a monthly budget will unlock your daily Safe Today limits.',
        followUpQuestions: const [
          'How much have I spent this month?',
          'Where did most of my money go?',
          'Am I spending too much on food?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 5. Merchant-Specific Spending Queries ("how much did I spend on Swiggy?", "Amazon spending")
    final merchantMatch = _findMatchingMerchant(cleanQuery, allTransactions);
    if (intent == FinancialIntent.spendingByMerchant || merchantMatch != null) {
      final merchantName = merchantMatch ?? _extractMerchantName(cleanQuery);
      final timeframe = _parseTimeframe(cleanQuery, now);
      final matched = allTransactions.where((t) {
        final matchesMerchant =
            t.merchant.toLowerCase().contains(merchantName.toLowerCase());
        final matchesType = t.type == TransactionType.debit;
        final matchesTime = timeframe.filter(t.date);
        return matchesMerchant && matchesType && matchesTime;
      }).toList();

      if (matched.isEmpty) {
        final res = FormattedMoneyBrainResponse(
          answer:
              'You haven\'t recorded any $merchantName transactions ${timeframe.label}.',
          reason:
              'Checked database records for merchant "$merchantName" ${timeframe.label}.',
          evidence: '0 matching transactions found.',
          suggestedAction:
              'Want to check a different merchant or see where most of your money went?',
          followUpQuestions: const [
            'How much have I spent this month?',
            'Where did most of my money go?',
            'How much can I safely spend today?',
          ],
        );
        _queryResponseCache[cacheKey] = res;
        return res;
      }

      final totalSpent = matched.fold<double>(0, (sum, t) => sum + t.amount);
      final avgOrder = totalSpent / matched.length;
      final highest = matched.reduce((a, b) => b.amount > a.amount ? b : a);

      final res = FormattedMoneyBrainResponse(
        answer:
            '$merchantName spending ${timeframe.label}\n\nYou’ve spent ${currency.format(totalSpent)} at $merchantName ${timeframe.label} across ${matched.length} transaction${matched.length != 1 ? 's' : ''} (Average ${currency.format(avgOrder)} per transaction). Largest transaction was ${currency.format(highest.amount)} on ${DateFormat('d MMM yyyy').format(highest.date)}.',
        reason:
            'Extracted from ${matched.length} verified $merchantName records in your local database.',
        evidence:
            'Latest transaction: ${currency.format(matched.first.amount)} on ${DateFormat('d MMM yyyy').format(matched.first.date)}.',
        suggestedAction:
            'Want to see your total food spending across all apps or check your daily limit?',
        followUpQuestions: [
          'How much did I spend on food?',
          'Where did I spend the most?',
          'What is my daily safe spending limit?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 6. Category-Specific Spending Queries ("how much i spend the food", "how much did I spend on food", "show my food expenses")
    if (intent == FinancialIntent.spendingByCategory ||
        _containsCategoryKeyword(cleanQuery)) {
      final matchedCat = _extractCategoryKeyword(cleanQuery);
      final timeframe = _parseTimeframe(cleanQuery, now);

      final matchedTxs = allTransactions.where((t) {
        final matchesCat = t.category.toLowerCase().contains(matchedCat) ||
            matchedCat.contains(t.category.toLowerCase());
        final matchesType = t.type == TransactionType.debit;
        final matchesTime = timeframe.filter(t.date);
        return matchesCat && matchesType && matchesTime;
      }).toList();

      final categoryDisplay = matchedCat[0].toUpperCase() + matchedCat.substring(1);

      if (matchedTxs.isEmpty) {
        final res = FormattedMoneyBrainResponse(
          answer:
              'You haven\'t recorded any $categoryDisplay expenses ${timeframe.label}.',
          reason:
              'No matching records found for $categoryDisplay in your local database.',
          evidence: '0 matching records found.',
          suggestedAction: 'Want to check a different category or see your total spending?',
          followUpQuestions: const [
            'How much have I spent this month?',
            'Where did most of my money go?',
            'How much can I safely spend today?',
          ],
        );
        _queryResponseCache[cacheKey] = res;
        return res;
      }

      final totalCat = matchedTxs.fold<double>(0, (sum, t) => sum + t.amount);
      final avgCat = totalCat / matchedTxs.length;
      final highest = matchedTxs.reduce((a, b) => b.amount > a.amount ? b : a);

      final res = FormattedMoneyBrainResponse(
        answer:
            '$categoryDisplay spending ${timeframe.label}\n\nYou’ve spent ${currency.format(totalCat)} total on $categoryDisplay across ${matchedTxs.length} transaction${matchedTxs.length != 1 ? 's' : ''} (average ${currency.format(avgCat)} per transaction). Largest expense was ${currency.format(highest.amount)} at ${highest.merchant} on ${DateFormat('d MMM yyyy').format(highest.date)}.',
        reason:
            'Calculated from ${matchedTxs.length} verified $categoryDisplay transactions recorded in your active profile.',
        evidence:
            'Top transaction: ${highest.merchant} for ${currency.format(highest.amount)} on ${DateFormat('d MMM yyyy').format(highest.date)}.',
        suggestedAction:
            'Want to see which merchants took most of your $categoryDisplay budget?',
        followUpQuestions: [
          'Where did most of my money go?',
          'How much have I spent this month?',
          'What is my daily safe spending limit?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    // 7. Timeframe Spending Queries ("what did I spend yesterday?", "how much did I spend this month?", "today spend", etc.)
    final timeframe = _parseTimeframe(cleanQuery, now);
    final periodTxs = allTransactions.where((t) {
      return t.type == TransactionType.debit && timeframe.filter(t.date);
    }).toList();

    if (periodTxs.isEmpty) {
      final res = FormattedMoneyBrainResponse(
        answer: 'You haven’t recorded any expenses ${timeframe.label}.',
        reason:
            'Scanned database for expenses matching ${timeframe.label}.',
        evidence: '0 expense transactions found for this timeframe.',
        suggestedAction:
            'Once you log expenses or scan your SMS, I’ll track your daily totals here.',
        followUpQuestions: const [
          'How much have I spent on food?',
          'Where did I spend the most?',
          'How much can I safely spend today?',
        ],
      );
      _queryResponseCache[cacheKey] = res;
      return res;
    }

    final totalSpent = periodTxs.fold<double>(0, (sum, t) => sum + t.amount);
    final highest = periodTxs.reduce((a, b) => b.amount > a.amount ? b : a);

    // Group by category
    final catMap = <String, double>{};
    for (final t in periodTxs) {
      catMap[t.category] = (catMap[t.category] ?? 0.0) + t.amount;
    }
    final sortedCats = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = sortedCats.first;
    final topCatPercent = ((topCat.value / totalSpent) * 100).round();

    final res = FormattedMoneyBrainResponse(
      answer:
          'Total spending ${timeframe.label}\n\nYou’ve spent ${currency.format(totalSpent)} total ${timeframe.label} across ${periodTxs.length} transaction${periodTxs.length != 1 ? 's' : ''}. ${topCat.key} is taking the biggest share at ${currency.format(topCat.value)} ($topCatPercent%), and your largest single expense was ${currency.format(highest.amount)} at ${highest.merchant}.',
      reason:
          'Aggregated from all ${periodTxs.length} expense transactions recorded ${timeframe.label}.',
      evidence:
          'Top category is ${topCat.key} representing $topCatPercent% of spending.',
      suggestedAction:
          'Want me to break down your other categories or check your daily Safe Today limit?',
      followUpQuestions: [
        'How much did I spend on ${topCat.key.toLowerCase()}?',
        'Where did I spend the most?',
        'How much can I safely spend today?',
      ],
    );
    _queryResponseCache[cacheKey] = res;
    return res;
  }

  // ── Helper Timeframe Extraction ──────────────────────────────────────────
  _QueryTimeframe _parseTimeframe(String cleanQuery, DateTime now) {
    if (cleanQuery.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return _QueryTimeframe(
        label: 'yesterday (${DateFormat('d MMM yyyy').format(yesterday)})',
        filter: (d) {
          final local = d.toLocal();
          return local.year == yesterday.year &&
              local.month == yesterday.month &&
              local.day == yesterday.day;
        },
      );
    }
    if (cleanQuery.contains('today')) {
      return _QueryTimeframe(
        label: 'today (${DateFormat('d MMM yyyy').format(now)})',
        filter: (d) {
          final local = d.toLocal();
          return local.year == now.year &&
              local.month == now.month &&
              local.day == now.day;
        },
      );
    }
    if (cleanQuery.contains('this week') ||
        cleanQuery.contains('past 7 days') ||
        cleanQuery.contains('last 7 days')) {
      final start = now.subtract(const Duration(days: 7));
      return _QueryTimeframe(
        label: 'this week',
        filter: (d) => !d.isBefore(start) && !d.isAfter(now),
      );
    }
    if (cleanQuery.contains('last month')) {
      final prevRange = MonthRange.previous();
      return _QueryTimeframe(
        label:
            'last month (${DateFormat('MMMM yyyy').format(prevRange.startInclusive)})',
        filter: (d) => prevRange.contains(d),
      );
    }
    if (cleanQuery.contains('all time') || cleanQuery.contains('overall')) {
      return _QueryTimeframe(
        label: 'overall',
        filter: (_) => true,
      );
    }

    // Default to canonical current month
    final currentRange = MonthRange.current();
    return _QueryTimeframe(
      label: 'this month (${DateFormat('MMMM yyyy').format(now)})',
      filter: (d) => currentRange.contains(d),
    );
  }

  bool _containsCategoryKeyword(String query) {
    const keywords = [
      'food',
      'dining',
      'restaurant',
      'swiggy',
      'zomato',
      'groceries',
      'grocery',
      'shopping',
      'clothes',
      'electronics',
      'fuel',
      'petrol',
      'diesel',
      'travel',
      'cab',
      'taxi',
      'flight',
      'train',
      'bills',
      'electricity',
      'recharge',
      'wifi',
      'entertainment',
      'movies',
      'ott',
      'medical',
      'health',
      'doctor',
      'pharmacy',
      'investments',
      'stocks',
      'salary'
    ];
    return keywords.any((k) => query.contains(k));
  }

  String _extractCategoryKeyword(String query) {
    if (query.contains('food') ||
        query.contains('dining') ||
        query.contains('restaurant') ||
        query.contains('eating') ||
        query.contains('groceries') ||
        query.contains('grocery')) {
      return 'food';
    }
    if (query.contains('shopping') ||
        query.contains('clothes') ||
        query.contains('electronics')) {
      return 'shopping';
    }
    if (query.contains('fuel') ||
        query.contains('petrol') ||
        query.contains('diesel')) {
      return 'fuel';
    }
    if (query.contains('travel') ||
        query.contains('cab') ||
        query.contains('taxi') ||
        query.contains('flight') ||
        query.contains('train') ||
        query.contains('transport')) {
      return 'travel';
    }
    if (query.contains('bill') ||
        query.contains('electricity') ||
        query.contains('water') ||
        query.contains('recharge') ||
        query.contains('wifi')) {
      return 'bills';
    }
    if (query.contains('entertainment') ||
        query.contains('movie') ||
        query.contains('ott')) {
      return 'entertainment';
    }
    if (query.contains('medical') ||
        query.contains('health') ||
        query.contains('pharmacy') ||
        query.contains('doctor')) {
      return 'medical';
    }
    if (query.contains('investment') || query.contains('stock')) {
      return 'investments';
    }
    if (query.contains('salary')) return 'salary';
    return 'general';
  }

  String? _findMatchingMerchant(
      String query, List<TransactionItem> allTransactions) {
    const commonMerchants = [
      'swiggy',
      'zomato',
      'amazon',
      'flipkart',
      'myntra',
      'blinkit',
      'zepto',
      'uber',
      'ola',
      'rapido',
      'netflix',
      'spotify',
      'hotstar',
      'airtel',
      'jio',
      'starbucks',
      'croma',
      'decathlon',
      'dmart',
      'apollo',
      'zerodha',
      'groww'
    ];

    for (final m in commonMerchants) {
      if (query.contains(m)) {
        return m.substring(0, 1).toUpperCase() + m.substring(1);
      }
    }

    for (final t in allTransactions) {
      if (t.merchant.isNotEmpty && query.contains(t.merchant.toLowerCase())) {
        return t.merchant;
      }
    }
    return null;
  }

  String _extractMerchantName(String query) {
    return 'Merchant';
  }
}

class _QueryTimeframe {
  final String label;
  final bool Function(DateTime date) filter;

  _QueryTimeframe({
    required this.label,
    required this.filter,
  });
}
