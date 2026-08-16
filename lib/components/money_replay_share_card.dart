import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class MoneyReplayShareCard extends StatelessWidget {
  final int year;
  final double totalSaved;
  final int savingsStreakDays;
  final String financialPersonality;
  final String topMilestone;

  const MoneyReplayShareCard({
    super.key,
    required this.year,
    required this.totalSaved,
    required this.savingsStreakDays,
    required this.financialPersonality,
    required this.topMilestone,
  });

  static void show(
    BuildContext context, {
    required int year,
    required double totalSaved,
    required int savingsStreakDays,
    required String financialPersonality,
    required String topMilestone,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: MoneyReplayShareCard(
          year: year,
          totalSaved: totalSaved,
          savingsStreakDays: savingsStreakDays,
          financialPersonality: financialPersonality,
          topMilestone: topMilestone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.electricCyan, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricCyan.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: AppTheme.electricCyan, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text('My $year Money Replay',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppTheme.textMuted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Saved Stat Callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL SAVED THIS YEAR',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(currency.format(totalSaved),
                    style: const TextStyle(
                        color: AppTheme.semanticSuccess,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SAVING STREAK',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('$savingsStreakDays Days 🔥',
                          style: const TextStyle(
                              color: AppTheme.dangerCoral,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FINANCIAL DNA',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(financialPersonality,
                          style: const TextStyle(
                              color: AppTheme.electricCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Top Milestone Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.purpleGlow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.purpleGlow.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded,
                    color: AppTheme.purpleGlow, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BIGGEST MILESTONE',
                          style: TextStyle(
                              color: AppTheme.purpleGlow,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(topMilestone,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Powered by Branding Footer
          const Center(
            child: Text('Powered by Sagiro • 100% Privacy First',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),

          // One Tap Share Buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Money Replay Card',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Money Replay Card copied to clipboard! Ready to share.'),
                    backgroundColor: AppTheme.semanticSuccess,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
