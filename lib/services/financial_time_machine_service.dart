import '../models/transaction.dart';

class TimeMachineReflection {
  final String transactionId;
  final String merchant;
  final double amount;
  final DateTime date;
  final double counterfactualFutureValue;
  final String reflectionQuestion;
  final String habitSavingsMessage;

  TimeMachineReflection({
    required this.transactionId,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.counterfactualFutureValue,
    required this.reflectionQuestion,
    required this.habitSavingsMessage,
  });
}

class FinancialTimeMachineService {
  /// Analyzes past major purchases and calculates counterfactual compounding values
  static List<TimeMachineReflection> generateReflections(
      List<TransactionItem> transactions) {
    final reflections = <TimeMachineReflection>[];
    final now = DateTime.now();

    final majorDebits = transactions
        .where((t) => t.type == TransactionType.debit && t.amount >= 2000)
        .toList();

    for (final tx in majorDebits) {
      final monthsAgo = (now.difference(tx.date).inDays / 30).clamp(1.0, 36.0);
      final compoundedFutureValue =
          tx.amount * (1.0 + (0.08 * (monthsAgo / 12)));

      reflections.add(TimeMachineReflection(
        transactionId:
            tx.id?.toString() ?? tx.date.millisecondsSinceEpoch.toString(),
        merchant: tx.merchant,
        amount: tx.amount,
        date: tx.date,
        counterfactualFutureValue: compoundedFutureValue,
        reflectionQuestion:
            'If you hadn\'t bought ${tx.merchant} (₹${tx.amount.toStringAsFixed(0)}), today you would have ₹${compoundedFutureValue.toStringAsFixed(0)} more in savings. Would you make the same decision?',
        habitSavingsMessage:
            'You optimized spending on ${tx.merchant}. Equivalent habit savings: ₹${(tx.amount * 0.18).toStringAsFixed(0)}.',
      ));
    }

    return reflections;
  }
}
