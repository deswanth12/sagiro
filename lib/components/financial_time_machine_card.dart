import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/financial_time_machine_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class FinancialTimeMachineCard extends StatefulWidget {
  final List<TransactionItem> transactions;

  const FinancialTimeMachineCard({super.key, required this.transactions});

  @override
  State<FinancialTimeMachineCard> createState() =>
      _FinancialTimeMachineCardState();
}

class _FinancialTimeMachineCardState extends State<FinancialTimeMachineCard> {
  String? _userFeedback;

  @override
  Widget build(BuildContext context) {
    final reflections =
        FinancialTimeMachineService.generateReflections(widget.transactions);
    if (reflections.isEmpty) return const SizedBox.shrink();

    final item = reflections.first;
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
                  Icon(Icons.history_toggle_off_rounded,
                      color: AppTheme.electricCyan, size: 20),
                  SizedBox(width: 8),
                  Text('FINANCIAL TIME MACHINE™',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0)),
                ],
              ),
              Text('REFLECT & LEARN',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              'Bought ${item.merchant} (${currency.format(item.amount)}) on ${DateFormat('dd MMM, yyyy').format(item.date)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5)),
          const SizedBox(height: 6),
          Text(
            'If you hadn\'t bought it, today you would have ${currency.format(item.counterfactualFutureValue)} more in savings buffer.',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (_userFeedback != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.semanticSuccess.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_userFeedback!,
                  style: const TextStyle(
                      color: AppTheme.semanticSuccess,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            )
          else ...[
            const Text('Would you still make the exact same decision today?',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.semanticSuccess,
                      side: const BorderSide(color: AppTheme.semanticSuccess),
                    ),
                    icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                    label: const Text('Yes 👍',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() => _userFeedback =
                          '✓ Recorded: Worth every rupee! Conscious spending aligned.');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerCoral,
                      side: const BorderSide(color: AppTheme.dangerCoral),
                    ),
                    icon: const Icon(Icons.thumb_down_alt_rounded, size: 16),
                    label: const Text('No, I\'d save 👎',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() => _userFeedback =
                          '✓ Saved lesson: Sagiro will remind you before future similar purchases!');
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
