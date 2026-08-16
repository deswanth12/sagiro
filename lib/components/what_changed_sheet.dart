import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class WhatChangedSheet extends StatelessWidget {
  final double spentYesterday;
  final double safeTodayLimit;
  final String? topCategoryShift;
  final int daysUntilPayday;
  final String? upcomingBillTitle;
  final double? upcomingBillAmount;

  const WhatChangedSheet({
    super.key,
    required this.spentYesterday,
    required this.safeTodayLimit,
    this.topCategoryShift,
    required this.daysUntilPayday,
    this.upcomingBillTitle,
    this.upcomingBillAmount,
  });

  static void show(
    BuildContext context, {
    required double spentYesterday,
    required double safeTodayLimit,
    String? topCategoryShift,
    required int daysUntilPayday,
    String? upcomingBillTitle,
    double? upcomingBillAmount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhatChangedSheet(
        spentYesterday: spentYesterday,
        safeTodayLimit: safeTodayLimit,
        topCategoryShift: topCategoryShift,
        daysUntilPayday: daysUntilPayday,
        upcomingBillTitle: upcomingBillTitle,
        upcomingBillAmount: upcomingBillAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: AppTheme.electricCyan, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppTheme.electricCyan, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What changed since yesterday?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(
                        'Only the meaningful updates that matter to your budget',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            borderColor: AppTheme.electricCyan.withOpacity(0.2),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (spentYesterday == 0 && topCategoryShift == null) ...[
                  _buildChangeItem(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.semanticSuccess,
                    title: 'Status',
                    value: 'No significant changes yet',
                  ),
                ] else ...[
                  _buildChangeItem(
                    icon: Icons.calendar_today_rounded,
                    color: AppTheme.electricCyan,
                    title: 'Spent Yesterday',
                    value: '₹${spentYesterday.toStringAsFixed(0)}',
                  ),
                  if (topCategoryShift != null) ...[
                    const Divider(color: Colors.white10, height: 20),
                    _buildChangeItem(
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.warningAmber,
                      title: 'Category Shift',
                      value: topCategoryShift!,
                    ),
                  ],
                ],
                const Divider(color: Colors.white10, height: 20),
                _buildChangeItem(
                  icon: Icons.payments_outlined,
                  color: AppTheme.semanticSuccess,
                  title: 'Salary Arrives',
                  value: 'In $daysUntilPayday days',
                ),
                if (upcomingBillTitle != null &&
                    upcomingBillAmount != null) ...[
                  const Divider(color: Colors.white10, height: 20),
                  _buildChangeItem(
                    icon: Icons.receipt_long_rounded,
                    color: AppTheme.dangerCoral,
                    title: '$upcomingBillTitle Due Soon',
                    value: '₹${upcomingBillAmount!.toStringAsFixed(0)}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
