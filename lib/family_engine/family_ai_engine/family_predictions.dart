class FamilyPredictions {
  /// Predicts goal completion timeline based strictly on actual monthly savings velocity.
  /// If savings velocity is <= 0 or data is missing, returns an honest insufficient data message.
  static String predictVacationCompletion(
    double currentSaved,
    double targetAmount, {
    double? monthlySavingsRate,
  }) {
    if (targetAmount <= 0 || currentSaved >= targetAmount) {
      return 'Target reached!';
    }

    final remaining = targetAmount - currentSaved;

    if (monthlySavingsRate == null || monthlySavingsRate <= 0) {
      return 'Insufficient savings velocity data to project completion timeline. Set a monthly budget and log savings to enable goal projections.';
    }

    final estimatedMonths = (remaining / monthlySavingsRate).ceil();
    if (estimatedMonths <= 1) {
      return 'Estimated completion within 1 month based on current monthly savings velocity of ₹${monthlySavingsRate.toStringAsFixed(0)}/mo.';
    }

    return 'Estimated completion in $estimatedMonths months based on current monthly savings velocity of ₹${monthlySavingsRate.toStringAsFixed(0)}/mo.';
  }
}
