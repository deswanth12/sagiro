import 'package:flutter/material.dart';
import '../services/subscription_detector_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SubscriptionRenewalGuardianCard extends StatelessWidget {
  final List<DetectedSubscription> subscriptions;

  const SubscriptionRenewalGuardianCard({
    super.key,
    required this.subscriptions,
  });

  @override
  Widget build(BuildContext context) {
    final upcoming = subscriptions
        .where((s) => s.daysUntilRenewal >= 0 && s.daysUntilRenewal <= 7)
        .toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final sub = upcoming.first;

    return GlassCard(
      borderColor: AppTheme.warningAmber.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(sub.iconEmoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUBSCRIPTION RENEWAL GUARDIAN',
                  style: TextStyle(
                      color: AppTheme.warningAmber,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sub.merchant} (₹${sub.amount.toStringAsFixed(0)}) auto-renews in ${sub.daysUntilRenewal == 0 ? "today" : "${sub.daysUntilRenewal} days"}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                const Text('Tap to review or cancel before auto-debit',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
