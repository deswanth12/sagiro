import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weekly_review_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

import '../models/upcoming_bill.dart';

class WeeklyReviewCard extends StatelessWidget {
  final List<TransactionItem> transactions;
  final List<UpcomingBill> upcomingBills;
  final double monthlyBudget;
  final double safeTodayLimit;

  const WeeklyReviewCard({
    super.key,
    required this.transactions,
    this.upcomingBills = const [],
    this.monthlyBudget = 0.0,
    this.safeTodayLimit = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final report = WeeklyReviewService.generateWeeklyReview(
      transactions,
      upcomingBills: upcomingBills,
      monthlyBudget: monthlyBudget,
      safeTodayLimit: safeTodayLimit,
    );

    return GlassCard(
      borderColor: AppTheme.purpleGlow.withOpacity(0.35),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars_rounded,
                      color: AppTheme.purpleGlow, size: 20),
                  SizedBox(width: 8),
                  Text('WEEKLY REVIEW & CONFIDENCE SCORE',
                      style: TextStyle(
                          color: AppTheme.purpleGlow,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.semanticSuccess.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.semanticSuccess),
                ),
                child: Text('${report.confidenceScore}% Confidence',
                    style: const TextStyle(
                        color: AppTheme.semanticSuccess,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReviewStat('Spent This Week',
                  currency.format(report.weeklySpent), AppTheme.dangerCoral),
              _buildReviewStat(
                  'Saved This Week',
                  currency.format(report.weeklySaved),
                  AppTheme.semanticSuccess),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 10),
          ...report.confidencePillars.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(p,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              )),
          const SizedBox(height: 10),
          Text(report.gentleRecommendation,
              style: const TextStyle(
                  color: AppTheme.electricCyan,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildReviewStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}
