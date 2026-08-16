import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../services/data_health_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';

class DuplicatePair {
  final TransactionItem itemA;
  final TransactionItem itemB;

  const DuplicatePair({required this.itemA, required this.itemB});
}

class DuplicateReviewPage extends StatefulWidget {
  const DuplicateReviewPage({super.key});

  @override
  State<DuplicateReviewPage> createState() => _DuplicateReviewPageState();
}

class _DuplicateReviewPageState extends State<DuplicateReviewPage> {
  final Set<String> _ignoredPairKeys = {};

  List<DuplicatePair> _findDuplicatePairs(List<TransactionItem> transactions) {
    final List<DuplicatePair> pairs = [];
    final Map<String, TransactionItem> seenHashes = {};

    for (final tx in transactions) {
      final hash = DataHealthService.computeTxHash(tx);
      if (seenHashes.containsKey(hash)) {
        final existing = seenHashes[hash]!;
        final pairKey = '${existing.id}_${tx.id}';
        if (!_ignoredPairKeys.contains(pairKey)) {
          pairs.add(DuplicatePair(itemA: existing, itemB: tx));
        }
      } else {
        seenHashes[hash] = tx;
      }
    }

    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicate Review Interface', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final pairs = _findDuplicatePairs(provider.transactions);

          if (pairs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.semanticSuccess, size: 64),
                  const SizedBox(height: 16),
                  Text('Zero Duplicates Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor(context))),
                  const SizedBox(height: 6),
                  Text('All transactions in your database are unique.', style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pairs.length,
            itemBuilder: (context, index) {
              final pair = pairs[index];
              final key = '${pair.itemA.id}_${pair.itemB.id}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.copy_rounded, color: AppTheme.warningAmber, size: 20),
                            const SizedBox(width: 8),
                            Text('Possible Duplicate Match', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor(context), fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Item A vs Item B Cards
                        Row(
                          children: [
                            Expanded(child: _buildTransactionTile(context, pair.itemA, 'Source 1: ${pair.itemA.source.name.toUpperCase()}', dateFormat)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildTransactionTile(context, pair.itemB, 'Source 2: ${pair.itemB.source.name.toUpperCase()}', dateFormat)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Prompt & Action Buttons
                        Text(
                          'Are these the exact same transaction?',
                          style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.electricCyan),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _ignoredPairKeys.add(key);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Retained both transactions separately.')),
                                  );
                                },
                                child: const Text('Keep Both', style: TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.electricMint,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _ignoredPairKeys.add(key);
                                  });
                                  if (pair.itemB.id != null) {
                                    provider.deleteTransaction(pair.itemB.id!);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('🟢 Merged duplicates safely into 1 record.')),
                                  );
                                },
                                child: const Text('Merge (Delete 1)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
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

  Widget _buildTransactionTile(BuildContext context, TransactionItem item, String header, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.elevatedCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: const TextStyle(color: AppTheme.electricCyan, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('₹${item.amount.toStringAsFixed(2)}', style: TextStyle(color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(item.merchant, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(dateFormat.format(item.date), style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 11)),
        ],
      ),
    );
  }
}
