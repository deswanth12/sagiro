class MoneyWeatherForecast {
  final String status; // Sunny ☀️, Cloudy ⛅, Heavy Spending Ahead 🌧️
  final String riskText;
  final double safeAmount;
  final String tip;

  MoneyWeatherForecast({
    required this.status,
    required this.riskText,
    required this.safeAmount,
    required this.tip,
  });
}

class SpendingPersonality {
  final String title; // The Planner, Weekend Spender, Food Explorer, The Saver
  final String description;
  final String iconEmoji;

  SpendingPersonality({
    required this.title,
    required this.description,
    required this.iconEmoji,
  });
}

class DailyWin {
  final double amountSavedUnderSafeLimit;
  final bool isWin;
  final String message;

  DailyWin({
    required this.amountSavedUnderSafeLimit,
    required this.isWin,
    required this.message,
  });
}
