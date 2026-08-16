import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class MultiCategoryFilterSheet extends StatefulWidget {
  final List<TransactionItem> transactions;
  final Set<String> initialSelectedCategories;
  final Function(Set<String> selectedCategories) onApplyFilter;

  const MultiCategoryFilterSheet({
    super.key,
    required this.transactions,
    required this.initialSelectedCategories,
    required this.onApplyFilter,
  });

  static void show(
    BuildContext context, {
    required List<TransactionItem> transactions,
    required Set<String> initialSelectedCategories,
    required Function(Set<String> selectedCategories) onApplyFilter,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiCategoryFilterSheet(
        transactions: transactions,
        initialSelectedCategories: initialSelectedCategories,
        onApplyFilter: onApplyFilter,
      ),
    );
  }

  @override
  State<MultiCategoryFilterSheet> createState() =>
      _MultiCategoryFilterSheetState();
}

class _MultiCategoryFilterSheetState extends State<MultiCategoryFilterSheet> {
  late Set<String> _selected;

  static const List<String> _allCategories = [
    'Food',
    'Groceries',
    'Fuel',
    'Shopping',
    'Electronics',
    'Travel',
    'Medical',
    'Entertainment',
    'Bills',
    'Rent',
    'EMI',
    'Recharge',
    'Investments',
    'Personal Care',
    'Gift',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelectedCategories);
  }

  double get _combinedTotal {
    if (_selected.isEmpty) return 0.0;
    final now = DateTime.now();

    double sum = 0.0;
    for (final t in widget.transactions) {
      final local = t.date.toLocal();
      if (t.type == TransactionType.debit &&
          local.year == now.year &&
          local.month == now.month) {
        if (t.isSplit) {
          for (final split in t.splits!) {
            if (_selected.contains(split.category)) {
              sum += split.amount;
            }
          }
        } else {
          if (_selected.contains(t.category)) {
            sum += t.amount;
          }
        }
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border:
            Border(top: BorderSide(color: AppTheme.electricCyan, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle & Title
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Multi-Category Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selected.length} categories selected • Combined spending view',
                      style: const TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selected.length == _allCategories.length) {
                        _selected.clear();
                      } else {
                        _selected = Set.from(_allCategories);
                      }
                    });
                  },
                  child: Text(
                    _selected.length == _allCategories.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Combined Total Badge Card
            GlassCard(
              borderColor: AppTheme.electricMint.withOpacity(0.4),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMBINED SPENDING (THIS MONTH)',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currency.format(_combinedTotal),
                        style: const TextStyle(
                          color: AppTheme.electricMint,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.electricMint.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selected.isEmpty
                              ? 'Select categories below'
                              : _selected.join(' + '),
                          style: const TextStyle(
                              color: AppTheme.electricMint,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category Checkboxes List
            ..._allCategories.map((cat) {
              final isChecked = _selected.contains(cat);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: CheckboxListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  activeColor: AppTheme.electricCyan,
                  checkColor: Colors.black,
                  tileColor: AppTheme.darkCard,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  title: Text(
                    cat,
                    style: TextStyle(
                      color: isChecked ? Colors.white : AppTheme.textSecondary,
                      fontWeight:
                          isChecked ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  value: isChecked,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.add(cat);
                      } else {
                        _selected.remove(cat);
                      }
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 20),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  widget.onApplyFilter(_selected);
                  Navigator.pop(context);
                },
                child: const Text('Apply Multi-Category Filter',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
