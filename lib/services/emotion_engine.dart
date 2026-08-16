/// CardModuleType — Priority Modules for Control Screen
enum CardModuleType {
  heroSafeToday,
  livingGreeting,
  upcomingBillAlert,
  goalCelebration,
  todaysAdvice,
  recentActivity,
  moneyWeather,
  dailyMission,
}

/// TimeOfDayPhase — Temporal Awareness
enum TimeOfDayPhase {
  morning, // 5 AM - 11:59 AM ("Fresh Start")
  lunch, // 12 PM - 4:59 PM ("Halfway Through Today")
  evening, // 5 PM - 8:59 PM ("Evening Wind-down")
  night, // 9 PM - 4:59 AM ("You're Done for Today")
}

/// EmotionEngine — Central Context-Aware Engine.
/// Dynamically evaluates financial health, time of day, and milestone events
/// to determine card priority, copy, and ambient lighting.
class EmotionEngine {
  static TimeOfDayPhase getTimePhase() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return TimeOfDayPhase.morning;
    if (hour >= 12 && hour < 17) return TimeOfDayPhase.lunch;
    if (hour >= 17 && hour < 21) return TimeOfDayPhase.evening;
    return TimeOfDayPhase.night;
  }

  static String getTimePhaseSubhead() {
    switch (getTimePhase()) {
      case TimeOfDayPhase.morning:
        return 'Fresh Start • Make today count';
      case TimeOfDayPhase.lunch:
        return 'Halfway Through Today • Staying on track';
      case TimeOfDayPhase.evening:
        return 'Evening Reflection • Budget intact';
      case TimeOfDayPhase.night:
        return 'You\'re done for today • Sleep well';
    }
  }

  /// Evaluates Dynamic Card Module Priority Order
  static List<CardModuleType> getModulePriority({
    required double todaySpend,
    required double dailySafeLimit,
    required double monthSpend,
    required double monthlyBudget,
    required bool hasUpcomingBill,
    required bool hasCompletedGoal,
  }) {
    if (hasCompletedGoal) {
      return [
        CardModuleType.goalCelebration,
        CardModuleType.heroSafeToday,
        CardModuleType.todaysAdvice,
        CardModuleType.moneyWeather,
        CardModuleType.recentActivity,
      ];
    }

    if (hasUpcomingBill ||
        (monthlyBudget > 0 && monthSpend > monthlyBudget * 0.85)) {
      return [
        CardModuleType.upcomingBillAlert,
        CardModuleType.heroSafeToday,
        CardModuleType.todaysAdvice,
        CardModuleType.moneyWeather,
        CardModuleType.recentActivity,
      ];
    }

    // Standard Healthy Day Order
    return [
      CardModuleType.livingGreeting,
      CardModuleType.heroSafeToday,
      CardModuleType.todaysAdvice,
      CardModuleType.moneyWeather,
      CardModuleType.dailyMission,
      CardModuleType.recentActivity,
    ];
  }
}
