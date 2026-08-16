import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class AndroidWidgetPreviewCard extends StatelessWidget {
  final double safeTodayLimit;

  const AndroidWidgetPreviewCard({super.key, required this.safeTodayLimit});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.35),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.widgets_rounded,
                      color: AppTheme.electricCyan, size: 20),
                  SizedBox(width: 8),
                  Text('ANDROID HOME SCREEN WIDGETS',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0)),
                ],
              ),
              Text('ACTIVE',
                  style: TextStyle(
                      color: AppTheme.semanticSuccess,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Safe Today Home Widget Mockup
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.electricCyan.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppTheme.semanticSuccess, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🟢 SAFE TODAY™',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800)),
                      Text(
                          safeTodayLimit > 0
                              ? currency.format(safeTodayLimit)
                              : 'Set Budget',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                    ],
                  ),
                ),
                const Text('Everything healthy today',
                    style: TextStyle(
                        color: AppTheme.semanticSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Daily Financial Snapshot Widget
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('☀️ DAILY SNAPSHOT',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Good Morning! Track daily spend & recurring bills',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
