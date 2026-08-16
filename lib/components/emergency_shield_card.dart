import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class EmergencyShieldCard extends StatelessWidget {
  final double totalSaved;
  final double monthlyExpenses;

  const EmergencyShieldCard({
    super.key,
    required this.totalSaved,
    required this.monthlyExpenses,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyExpenses <= 0) {
      return GlassCard(
        borderColor: AppTheme.electricCyan.withOpacity(0.35),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_rounded,
                    color: AppTheme.electricCyan, size: 20),
                SizedBox(width: 8),
                Text('EMERGENCY SHIELD GAUGE',
                    style: TextStyle(
                        color: AppTheme.electricCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0)),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Log monthly expenses to calculate your emergency runway.',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final monthsCovered = (totalSaved / monthlyExpenses).clamp(0.0, 24.0);
    final daysCovered = (monthsCovered * 30).toInt();

    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.35),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded,
                      color: AppTheme.electricCyan, size: 20),
                  SizedBox(width: 8),
                  Text('EMERGENCY SHIELD GAUGE',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.0)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                    '${monthsCovered.toStringAsFixed(1)} Months Covered',
                    style: const TextStyle(
                        color: AppTheme.electricCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your liquid savings cover $daysCovered days of essential living expenses.',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10)),
              ),
              FractionallySizedBox(
                widthFactor: (monthsCovered / 6.0).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0 Months',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              Text(
                  'Target: 6.0 Months (${(monthsCovered / 6.0 * 100).toInt()}%)',
                  style: const TextStyle(
                      color: AppTheme.electricCyan,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
