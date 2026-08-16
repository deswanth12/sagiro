/// LivingState — Financial Health & Ambient Visual State.
enum LivingState {
  healthy, // 🟢 Everything on track, safe spend available
  caution, // 🟡 Spending velocity faster than usual
  alert, // 🔴 Upcoming bill due or low daily budget remaining
}

/// FinancialSeason — Temporal Financial Rhythms.
enum FinancialSeason {
  freshStart, // January - February
  momentum, // March - May
  checkpoint, // June - August
  reflection, // September - December
}

/// LivingUIState — Living UI Generator Engine.
/// Converts raw budget metrics into human, conversational guidance.
class LivingUIState {
  final LivingState state;
  final FinancialSeason season;
  final String greetingTitle;
  final String greetingBody;
  final String coffeeAdvice;
  final String whatChanged;
  final String nextBestMove;

  LivingUIState({
    required this.state,
    required this.season,
    required this.greetingTitle,
    required this.greetingBody,
    required this.coffeeAdvice,
    required this.whatChanged,
    required this.nextBestMove,
  });

  factory LivingUIState.fromMetrics({
    required String userName,
    required double todaySpend,
    required double dailySafeLimit,
    required double monthSpend,
    required double monthlyBudget,
    required bool hasUpcomingBill,
    String? upcomingBillTitle,
  }) {
    final now = DateTime.now();
    final month = now.month;

    // Determine Season
    FinancialSeason season = FinancialSeason.checkpoint;
    if (month == 1 || month == 2) {
      season = FinancialSeason.freshStart;
    } else if (month >= 3 && month <= 5) {
      season = FinancialSeason.momentum;
    } else if (month >= 6 && month <= 8) {
      season = FinancialSeason.checkpoint;
    } else {
      season = FinancialSeason.reflection;
    }

    final remainingDaily =
        (dailySafeLimit - todaySpend).clamp(0.0, dailySafeLimit);
    final budgetPercent =
        monthlyBudget > 0 ? (monthSpend / monthlyBudget) : 0.0;

    final String whatChangedText;
    final String nextBestMoveText;

    final remainingCushion =
        (monthlyBudget - monthSpend).clamp(0.0, monthlyBudget);

    if (hasUpcomingBill || remainingDaily < 200 || budgetPercent > 0.9) {
      final billNotice =
          upcomingBillTitle != null ? '$upcomingBillTitle is due soon. ' : '';
      return LivingUIState(
        state: LivingState.alert,
        season: season,
        greetingTitle: '🔴 Good ${_getTimeOfDayGreeting()}, $userName',
        greetingBody:
            '${billNotice}Only ₹${remainingDaily.toStringAsFixed(0)} remains for today. Delay unnecessary spending.',
        coffeeAdvice:
            'Skip non-essential expenses today to keep your bill payments safe.',
        whatChanged: 'Bill commitments due soon. Budget velocity is high.',
        nextBestMove: 'Review upcoming bills and pause non-essential shopping.',
      );
    } else if (budgetPercent > 0.75 ||
        (todaySpend > dailySafeLimit * 0.8 && dailySafeLimit > 0)) {
      whatChangedText = 'Not enough spending data to compare yet.';
      nextBestMoveText =
          'Keep your daily spend under ₹${dailySafeLimit.toStringAsFixed(0)} to rebuild your cushion.';

      return LivingUIState(
        state: LivingState.caution,
        season: season,
        greetingTitle: '🟡 Good ${_getTimeOfDayGreeting()}, $userName',
        greetingBody:
            'You\'re spending faster than usual this week. You still have ₹${remainingDaily.toStringAsFixed(0)} available.',
        coffeeAdvice:
            'Mindful spending recommended today. Avoid large impulse orders.',
        whatChanged: whatChangedText,
        nextBestMove: nextBestMoveText,
      );
    } else {
      whatChangedText = 'Not enough spending data to compare yet.';
      nextBestMoveText = remainingCushion > 0
          ? 'Remaining monthly budget cushion: ₹${remainingCushion.toStringAsFixed(0)}. Keep it up!'
          : 'Set a monthly budget to unlock savings insights.';

      return LivingUIState(
        state: LivingState.healthy,
        season: season,
        greetingTitle: '🟢 Good ${_getTimeOfDayGreeting()}, $userName',
        greetingBody:
            'Everything looks healthy today. You still have ₹${remainingDaily.toStringAsFixed(0)} available.',
        coffeeAdvice: 'Coffee won\'t affect your budget today.',
        whatChanged: whatChangedText,
        nextBestMove: nextBestMoveText,
      );
    }
  }

  static String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String get seasonBadgeText {
    switch (season) {
      case FinancialSeason.freshStart:
        return '🌱 Fresh Start Season';
      case FinancialSeason.momentum:
        return '⚡ Building Momentum';
      case FinancialSeason.checkpoint:
        return '🎯 Mid-Year Checkpoint';
      case FinancialSeason.reflection:
        return '✨ Reflection Season';
    }
  }
}
