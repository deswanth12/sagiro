import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SafeTodayPredictionCard extends StatelessWidget {
  final double currentSafeLimit;

  const SafeTodayPredictionCard({super.key, required this.currentSafeLimit});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (currentSafeLimit <= 0) {
      return GlassCard(
        borderColor: AppTheme.electricCyan.withOpacity(0.3),
        padding: const EdgeInsets.all(18),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SAFE TODAY™ DAILY PACING',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                Text('PACING',
                    style: TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)),
              ],
            ),
            SizedBox(height: 14),
            Text(
              'Set a monthly budget to calculate Safe Today',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final days = ['Today', 'Day +1', 'Day +2', 'Day +3'];

    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.3),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SAFE TODAY™ DAILY PACING',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              Text('PACING',
                  style: TextStyle(
                      color: AppTheme.electricCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final isToday = index == 0;
              final dayLabel = days[index];

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.electricCyan.withOpacity(0.15)
                        : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isToday
                            ? AppTheme.electricCyan
                            : Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      Text(dayLabel,
                          style: TextStyle(
                              color: isToday
                                  ? AppTheme.electricCyan
                                  : AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        currency.format(currentSafeLimit),
                        style: TextStyle(
                          color:
                              isToday ? AppTheme.semanticSuccess : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
