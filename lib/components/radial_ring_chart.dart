import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class RadialRingChart extends StatelessWidget {
  final Map<String, double> categoryBreakdown;
  final double monthlyBudget;

  const RadialRingChart({
    super.key,
    required this.categoryBreakdown,
    required this.monthlyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    if (categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      AppTheme.electricCyan,
      AppTheme.successGreen,
      AppTheme.warningAmber,
      AppTheme.dangerCoral,
      AppTheme.purpleGlow,
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Category Progress Orbits',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text('RADIAL RINGS',
                  style: TextStyle(
                      color: AppTheme.electricCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            children:
                categoryBreakdown.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final color = colors[idx % colors.length];
              final pct = monthlyBudget > 0
                  ? (cat.value / monthlyBudget).clamp(0.0, 1.0)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(cat.key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ],
                        ),
                        Text(currency.format(cat.value),
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
