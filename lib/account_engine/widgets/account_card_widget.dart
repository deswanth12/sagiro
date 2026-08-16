import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/account_type.dart';
import '../../theme/app_theme.dart';
import '../../components/glass_card.dart';

class AccountCardWidget extends StatelessWidget {
  final AccountModel account;
  final double spentAmount;
  final double incomeAmount;
  final VoidCallback? onTap;

  const AccountCardWidget({
    super.key,
    required this.account,
    required this.spentAmount,
    required this.incomeAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isLiability = account.accountType.isLiability;
    final color = isLiability ? AppTheme.warningAmber : AppTheme.electricMint;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(account.iconEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(account.nickname,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        if (account.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Primary',
                                style: TextStyle(
                                    color: AppTheme.electricCyan,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${account.bankName} • ${account.maskedAccountNumber}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(account.estimatedBalance),
                    style: TextStyle(
                      color: isLiability ? AppTheme.dangerCoral : color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    isLiability ? 'Payment Due' : 'Balance',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spent: ${currency.format(spentAmount)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              if (incomeAmount > 0)
                Text('Income: ${currency.format(incomeAmount)}',
                    style: const TextStyle(
                        color: AppTheme.semanticSuccess,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
