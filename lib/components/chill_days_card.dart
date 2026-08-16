import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ChillDaysCard extends StatelessWidget {
  final int chillDaysThisWeek;
  final double estimatedSaved;

  const ChillDaysCard({
    super.key,
    required this.chillDaysThisWeek,
    required this.estimatedSaved,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.semanticSuccess.withOpacity(0.35),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.semanticSuccess.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Text('🧘', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHILL DAYS THIS WEEK',
                  style: TextStyle(
                      color: AppTheme.semanticSuccess,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  '$chillDaysThisWeek Chill Days 🧘',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saved ~₹${estimatedSaved.toStringAsFixed(0)} by keeping spending zero or essential-only.',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
