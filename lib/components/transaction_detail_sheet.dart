import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'add_transaction_dialog.dart';
import 'split_transaction_dialog.dart';

class TransactionDetailSheet extends StatelessWidget {
  final TransactionItem transaction;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
  });

  static void show(BuildContext context, TransactionItem transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailSheet(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.type == TransactionType.debit;
    final formattedDate =
        DateFormat('EEEE, MMM d, yyyy • h:mm a').format(transaction.date);
    final amountColor =
        isDebit ? AppTheme.semanticDanger : AppTheme.semanticSuccess;
    final amountPrefix = isDebit ? '-₹' : '+₹';
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    final bgColor = AppTheme.backgroundColor(context);
    final surfaceColor = AppTheme.surfaceColor(context);
    final cardColor = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: const Border(
            top: BorderSide(color: AppTheme.semanticInfo, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Row: Merchant & Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      _getCategoryColor(transaction.category).withOpacity(0.18),
                  child: Icon(
                    _getCategoryIcon(transaction.category),
                    color: _getCategoryColor(transaction.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Trust Signal Pill (if from SMS)
            if (transaction.source == TransactionSource.sms) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.semanticInfo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.semanticInfo.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: AppTheme.semanticInfo, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Detected from bank SMS (100% On-Device)',
                      style: TextStyle(
                        color: AppTheme.semanticInfo,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Transaction Details Glass Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppTheme.cardBorder,
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Category',
                    value: transaction.category,
                    icon: _getCategoryIcon(transaction.category),
                    color: _getCategoryColor(transaction.category),
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 20),
                  _buildDetailRow(
                    label: 'Account',
                    value: transaction.account ?? 'Default Account',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.semanticInfo,
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 20),
                  _buildDetailRow(
                    label: 'Source',
                    value: _getSourceLabel(transaction),
                    icon: _getSourceIcon(transaction),
                    color: transaction.sourceTypes.length > 1
                        ? AppTheme.electricCyan
                        : textSecondary,
                  ),
                  if (transaction.transactionReference != null &&
                      transaction.transactionReference!.isNotEmpty) ...[
                    const Divider(color: AppTheme.cardBorder, height: 20),
                    _buildDetailRow(
                      label: 'Reference / UTR',
                      value: transaction.transactionReference!,
                      icon: Icons.tag_rounded,
                      color: AppTheme.electricMint,
                    ),
                  ],
                  if (transaction.notes != null &&
                      transaction.notes!.isNotEmpty) ...[
                    const Divider(color: AppTheme.cardBorder, height: 20),
                    _buildDetailRow(
                      label: 'Notes',
                      value: transaction.notes!,
                      icon: Icons.notes_rounded,
                      color: textSecondary,
                    ),
                  ],
                ],
              ),
            ),

            // Category Splits Card if present
            if (transaction.splits != null &&
                transaction.splits!.isNotEmpty) ...[
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppTheme.semanticSuccess.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.call_split_rounded,
                            color: AppTheme.semanticSuccess, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Category Splits',
                          style: TextStyle(
                            color: AppTheme.semanticSuccess,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...transaction.splits!.map(
                      (split) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              split.category,
                              style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₹${split.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppTheme.semanticSuccess,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons: Edit, Split, Delete
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AddTransactionDialog(
                          transactionToEdit: transaction,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),

                // Split Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.semanticInfo.withOpacity(0.15),
                      foregroundColor: AppTheme.semanticInfo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                            color: AppTheme.semanticInfo, width: 1),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => SplitTransactionDialog(
                          transaction: transaction,
                          onSave: (splits) async {
                            final updated = transaction.copyWith(
                              category: 'Split (${splits.length} categories)',
                              splits: splits,
                            );
                            await budgetProvider.updateTransaction(updated);
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.call_split_rounded, size: 18),
                    label: const Text('Split',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),

                // Delete Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.semanticDanger.withOpacity(0.15),
                      foregroundColor: AppTheme.semanticDanger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                            color: AppTheme.semanticDanger, width: 1),
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: surfaceColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: Text(
                            'Delete this transaction?',
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'This will remove the transaction from your Timeline.',
                            style: TextStyle(color: textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel',
                                  style: TextStyle(color: textSecondary)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.semanticDanger,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        if (context.mounted) Navigator.pop(context);
                        final deletedTx = transaction;
                        if (transaction.id != null) {
                          await budgetProvider
                              .deleteTransaction(transaction.id!);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted ${deletedTx.merchant}'),
                              backgroundColor: surfaceColor,
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: AppTheme.semanticInfo,
                                onPressed: () async {
                                  await budgetProvider.undoLastAction();
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Builder(
      builder: (context) {
        final textPrimary = AppTheme.textPrimaryColor(context);
        final textSecondary = AppTheme.textSecondaryColor(context);

        return Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'fuel':
      case 'transport':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'salary':
      case 'income':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return Colors.orangeAccent;
      case 'shopping':
        return Colors.purpleAccent;
      case 'fuel':
      case 'transport':
      case 'travel':
        return AppTheme.electricCyan;
      case 'entertainment':
        return Colors.pinkAccent;
      case 'bills':
      case 'utilities':
        return AppTheme.dangerCoral;
      case 'salary':
      case 'income':
        return AppTheme.electricMint;
      default:
        return Colors.blueAccent;
    }
  }

  String _getSourceLabel(TransactionItem tx) {
    if (tx.sourceTypes.length > 1) {
      return 'Multi-Source (${tx.displaySource})';
    }
    switch (tx.source) {
      case TransactionSource.sms:
        return 'Bank SMS Scan';
      case TransactionSource.pdf:
        return 'PDF Bank Statement';
      case TransactionSource.csv:
        return 'CSV Statement Import';
      case TransactionSource.excel:
        return 'Excel Statement Import';
      case TransactionSource.ocr:
        return 'Camera / Document OCR';
      case TransactionSource.manual:
        return 'Manual Entry';
      case TransactionSource.voice:
        return 'Voice AI Entry';
      case TransactionSource.backup:
        return 'Backup Archive Restore';
    }
  }

  IconData _getSourceIcon(TransactionItem tx) {
    if (tx.sourceTypes.length > 1) {
      return Icons.merge_type_rounded;
    }
    switch (tx.source) {
      case TransactionSource.sms:
        return Icons.sms_rounded;
      case TransactionSource.pdf:
        return Icons.picture_as_pdf_rounded;
      case TransactionSource.csv:
        return Icons.table_chart_rounded;
      case TransactionSource.excel:
        return Icons.grid_on_rounded;
      case TransactionSource.ocr:
        return Icons.document_scanner_rounded;
      case TransactionSource.manual:
        return Icons.edit_note_rounded;
      case TransactionSource.voice:
        return Icons.mic_rounded;
      case TransactionSource.backup:
        return Icons.cloud_download_rounded;
    }
  }
}
