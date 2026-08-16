import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'animated_scale_button.dart';

/// MerchantAnalyticsSheet — Merchant Intelligence Bottom Sheet.
/// Triggered when tapping a transaction in Timeline. Zero page bloat.
class MerchantAnalyticsSheet extends StatelessWidget {
  final TransactionItem transaction;

  const MerchantAnalyticsSheet({super.key, required this.transaction});

  static void show(BuildContext context, TransactionItem transaction) {
    AppTheme.triggerHaptic(HapticFeedbackType.selection);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MerchantAnalyticsSheet(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.crispBorder),
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Merchant Header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.semanticInfo.withOpacity(0.15),
                child: const Icon(Icons.storefront_rounded,
                    color: AppTheme.semanticInfo, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.category} • Merchant Analytics',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Overview Grid
          Row(
            children: [
              Expanded(child: _buildStatBox('ORDERS LOGGED', '18 Orders')),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildStatBox('TOTAL SPENT',
                      '₹${(transaction.amount * 18).toStringAsFixed(0)}')),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildStatBox('AVG ORDER',
                      '₹${transaction.amount.toStringAsFixed(0)}')),
            ],
          ),
          const SizedBox(height: 16),

          // Savings Suggestion Card
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            borderColor: AppTheme.semanticSuccess.withOpacity(0.3),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: AppTheme.semanticSuccess, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart Savings Suggestion',
                          style: TextStyle(
                              color: AppTheme.semanticSuccess,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Cooking twice this week could save ₹900.',
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: AnimatedScaleButton(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.semanticInfo,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('Close Merchant Summary',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String val) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.crispBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(val,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
