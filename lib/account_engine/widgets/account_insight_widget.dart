import 'package:flutter/material.dart';
import '../models/account_insight.dart';
import '../../theme/app_theme.dart';
import '../../components/glass_card.dart';

class AccountInsightWidget extends StatelessWidget {
  final AccountInsight insight;

  const AccountInsightWidget({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.25),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(insight.detail,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
