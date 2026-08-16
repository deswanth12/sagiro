import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/statement_result.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../components/glass_card.dart';

class ImportPreviewSheet extends StatefulWidget {
  final StatementResult result;
  final Function(List<TransactionItem> confirmedTransactions) onConfirmImport;

  const ImportPreviewSheet({
    super.key,
    required this.result,
    required this.onConfirmImport,
  });

  @override
  State<ImportPreviewSheet> createState() => _ImportPreviewSheetState();
}

class _ImportPreviewSheetState extends State<ImportPreviewSheet> {
  late List<StatementResultItem> _items;
  late Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.result.items);
    // Select all non-duplicate items by default
    _selectedIndices = {};
    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].isDuplicate) {
        _selectedIndices.add(i);
      }
    }
  }

  void _selectAll() {
    setState(() {
      _selectedIndices = List.generate(_items.length, (i) => i).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _toggleItem(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _editItem(int index) async {
    final item = _items[index];
    final tx = item.transaction;

    final merchantCtrl = TextEditingController(text: tx.merchant);
    final amountCtrl =
        TextEditingController(text: tx.amount.toStringAsFixed(2));
    TransactionType selectedType = tx.type;

    final updated = await showDialog<TransactionItem>(
      context: context,
      builder: (ctx) {
        final cardBg = AppTheme.cardColor(context);
        final surfaceBg = AppTheme.surfaceColor(context);
        final textPri = AppTheme.textPrimaryColor(context);

        return StatefulBuilder(builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: cardBg,
            title: Text('Edit Transaction',
                style: TextStyle(
                    color: textPri, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: merchantCtrl,
                    style: TextStyle(color: textPri),
                    decoration: InputDecoration(
                      labelText: 'Merchant / Description',
                      labelStyle: const TextStyle(color: AppTheme.electricCyan),
                      filled: true,
                      fillColor: surfaceBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textPri),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      labelStyle: const TextStyle(color: AppTheme.electricCyan),
                      filled: true,
                      fillColor: surfaceBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Expense (Debit)'),
                          selected: selectedType == TransactionType.debit,
                          selectedColor: AppTheme.dangerCoral.withOpacity(0.3),
                          onSelected: (val) {
                            if (val) {
                              setDlgState(
                                  () => selectedType = TransactionType.debit);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Income (Credit)'),
                          selected: selectedType == TransactionType.credit,
                          selectedColor: AppTheme.successGreen.withOpacity(0.3),
                          onSelected: (val) {
                            if (val) {
                              setDlgState(
                                  () => selectedType = TransactionType.credit);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final newMerchant = merchantCtrl.text.trim();
                  final newAmt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (newMerchant.isEmpty || newAmt <= 0) return;

                  final newTx = tx.copyWith(
                    merchant: newMerchant,
                    amount: newAmt,
                    type: selectedType,
                  );
                  Navigator.pop(ctx, newTx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (updated != null) {
      setState(() {
        _items[index] = StatementResultItem(
          transaction: updated,
          confidence: item.confidence,
          isDuplicate: item.isDuplicate,
        );
        _selectedIndices.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    final selectedCount = _selectedIndices.length;
    double selectedExpense = 0;
    double selectedIncome = 0;

    for (final idx in _selectedIndices) {
      if (idx < _items.length) {
        final tx = _items[idx].transaction;
        if (tx.type == TransactionType.debit) {
          selectedExpense += tx.amount;
        } else {
          selectedIncome += tx.amount;
        }
      }
    }

    final bgColor = AppTheme.backgroundColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Statement Preview',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.result.health.healthBadge,
                      style: const TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary Stats Pill Bar
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    label: 'Found',
                    count: _items.length,
                    color: AppTheme.electricCyan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: 'Selected',
                    count: selectedCount,
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: 'Duplicates',
                    count: widget.result.duplicateCount,
                    color: AppTheme.warningAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Totals Bar & Selection Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: _selectAll,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Select All',
                          style: TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _deselectAll,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Clear All',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(
                  '-${currency.format(selectedExpense)} • +${currency.format(selectedIncome)}',
                  style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppTheme.cardBorder),
                itemBuilder: (ctx, idx) {
                  final item = _items[idx];
                  final tx = item.transaction;
                  final isSelected = _selectedIndices.contains(idx);

                  return GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    borderColor: isSelected
                        ? AppTheme.electricCyan.withOpacity(0.4)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppTheme.electricCyan,
                          checkColor: Colors.black,
                          onChanged: (_) => _toggleItem(idx),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _editItem(idx),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tx.merchant,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${tx.type == TransactionType.debit ? '-' : '+'}${currency.format(tx.amount)}',
                                      style: TextStyle(
                                        color: tx.type == TransactionType.debit
                                            ? AppTheme.dangerCoral
                                            : AppTheme.successGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy').format(tx.date),
                                      style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 11),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: item.isDuplicate
                                          ? const Text('Duplicate',
                                              style: TextStyle(
                                                  color: AppTheme.warningAmber,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold))
                                          : Text(
                                              item.confidence.summaryReason,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: item.confidence.color,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AppTheme.textMuted),
                          onPressed: () => _editItem(idx),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.download_done_rounded),
                label: Text(
                  selectedCount > 0
                      ? 'Add $selectedCount Selected Transactions'
                      : 'No Transactions Selected',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: selectedCount > 0
                    ? () {
                        final confirmed = _selectedIndices
                            .map((i) => _items[i].transaction)
                            .toList();
                        widget.onConfirmImport(confirmed);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
