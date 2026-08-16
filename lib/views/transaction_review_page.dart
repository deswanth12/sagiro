import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../services/transaction_confidence_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';

class TransactionReviewPage extends StatefulWidget {
  const TransactionReviewPage({super.key});

  @override
  State<TransactionReviewPage> createState() => _TransactionReviewPageState();
}

class _TransactionReviewPageState extends State<TransactionReviewPage> {
  final Map<int, bool> _reviewedIds = {};

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Review Queue', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final reviewQueue = provider.transactions.where((tx) {
            if (tx.id != null && _reviewedIds[tx.id!] == true) return false;
            final confidence = TransactionConfidenceService.evaluate(tx);
            return confidence.level != TransactionConfidenceLevel.high;
          }).toList();

          if (reviewQueue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.semanticSuccess, size: 64),
                  const SizedBox(height: 16),
                  Text('All Clear!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor(context))),
                  const SizedBox(height: 6),
                  Text('No transactions currently require user review.', style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reviewQueue.length,
            itemBuilder: (context, index) {
              final tx = reviewQueue[index];
              final confidence = TransactionConfidenceService.evaluate(tx);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              confidence.badgeText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: confidence.level == TransactionConfidenceLevel.needsReview
                                     ? AppTheme.warningAmber
                                     : AppTheme.semanticDanger,
                              ),
                            ),
                            Text(
                              '₹${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Merchant: ${tx.merchant.isEmpty ? "Unknown" : tx.merchant}',
                          style: TextStyle(color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${dateFormat.format(tx.date)} • Category: ${tx.category}',
                          style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedCardColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.warningAmber, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  confidence.reason,
                                  style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                if (tx.id != null) {
                                  setState(() {
                                    _reviewedIds[tx.id!] = true;
                                  });
                                  provider.deleteTransaction(tx.id!);
                                }
                              },
                              child: const Text('Discard', style: TextStyle(color: AppTheme.dangerCoral)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.electricCyan,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                if (tx.id != null) {
                                  setState(() {
                                    _reviewedIds[tx.id!] = true;
                                  });
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('🟢 Verified transaction: ${tx.merchant}')),
                                );
                              },
                              child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
