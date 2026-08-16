import 'package:flutter/material.dart';
import '../models/habit_loop.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// MoneyWeatherCard — Ambient Weather Forecast Widget.
/// Emotional Goal: Reduce financial anxiety with simple, peaceful weather metaphors.
class MoneyWeatherCard extends StatelessWidget {
  final MoneyWeatherForecast forecast;

  const MoneyWeatherCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppTheme.semanticSuccess;
    IconData weatherIcon = Icons.wb_sunny_rounded;

    if (forecast.status.contains('Rain') ||
        forecast.status.contains('Storm') ||
        forecast.status.contains('🌧️')) {
      statusColor = AppTheme.semanticDanger;
      weatherIcon = Icons.thunderstorm_rounded;
    } else if (forecast.status.contains('Cloud') ||
        forecast.status.contains('⛅')) {
      statusColor = AppTheme.semanticWarning;
      weatherIcon = Icons.cloud_rounded;
    }

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      borderColor: statusColor.withOpacity(0.25),
      backgroundColor: AppTheme.darkCard.withOpacity(0.55),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(weatherIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      forecast.status,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  forecast.tip.isNotEmpty ? forecast.tip : forecast.riskText,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
