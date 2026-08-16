import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'animated_scale_button.dart';

class SplitTransactionDialog extends StatefulWidget {
  final TransactionItem transaction;
  final Function(List<TransactionSplit> splits) onSave;

  const SplitTransactionDialog({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  State<SplitTransactionDialog> createState() => _SplitTransactionDialogState();
}

class _SplitTransactionDialogState extends State<SplitTransactionDialog> {
  final List<TextEditingController> _amountControllers = [];
  final List<String> _selectedCategories = [];

  static const List<String> _allCategories = [
    'Shopping',
    'Electronics',
    'Food',
    'Groceries',
    'Fuel',
    'Medical',
    'Travel',
    'Entertainment',
    'Gift',
    'Recharge',
    'Bills',
    'Rent',
    'EMI',
    'Investments',
    'Education',
    'Personal Care',
    'Pets',
    'Taxes',
    'Household',
    'General',
  ];

  bool _showSmartSuggestion = false;
  List<TransactionSplit>? _smartSuggestion;

  @override
  void initState() {
    super.initState();
    _initSplits();
    _checkSmartSplitSuggestion();
  }

  void _initSplits() {
    final existing = widget.transaction.splits;
    if (existing != null && existing.isNotEmpty) {
      for (final s in existing) {
        _selectedCategories.add(s.category);
        _amountControllers
            .add(TextEditingController(text: s.amount.toStringAsFixed(0)));
      }
    } else {
      // Default initial 2 rows (50/50 split of original amount)
      final half = widget.transaction.amount / 2;
      _selectedCategories.add(widget.transaction.category);
      _amountControllers
          .add(TextEditingController(text: half.toStringAsFixed(0)));

      final secondCat =
          widget.transaction.category == 'Shopping' ? 'Electronics' : 'General';
      _selectedCategories.add(secondCat);
      _amountControllers.add(TextEditingController(
          text: (widget.transaction.amount - half).toStringAsFixed(0)));
    }
  }

  void _checkSmartSplitSuggestion() {
    final merchant = widget.transaction.merchant.toLowerCase();
    final amount = widget.transaction.amount;

    if (merchant.contains('amazon') || merchant.contains('flipkart')) {
      _smartSuggestion = [
        TransactionSplit(
            category: 'Electronics', amount: (amount * 0.7).roundToDouble()),
        TransactionSplit(
            category: 'Household', amount: (amount * 0.3).roundToDouble()),
      ];
      _showSmartSuggestion = true;
    } else if (merchant.contains('mart') ||
        merchant.contains('supermarket') ||
        merchant.contains('blinkit') ||
        merchant.contains('zepto')) {
      _smartSuggestion = [
        TransactionSplit(
            category: 'Groceries', amount: (amount * 0.6).roundToDouble()),
        TransactionSplit(
            category: 'Personal Care', amount: (amount * 0.4).roundToDouble()),
      ];
      _showSmartSuggestion = true;
    }
  }

  void _applySmartSplit() {
    if (_smartSuggestion == null) return;
    setState(() {
      _clearControllers();
      for (final s in _smartSuggestion!) {
        _selectedCategories.add(s.category);
        _amountControllers
            .add(TextEditingController(text: s.amount.toStringAsFixed(0)));
      }
      _showSmartSuggestion = false;
    });
  }

  void _clearControllers() {
    for (final c in _amountControllers) {
      c.dispose();
    }
    _amountControllers.clear();
    _selectedCategories.clear();
  }

  @override
  void dispose() {
    for (final c in _amountControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAllocated {
    double sum = 0.0;
    for (final c in _amountControllers) {
      sum += double.tryParse(c.text) ?? 0.0;
    }
    return sum;
  }

  double get _remaining {
    return widget.transaction.amount - _totalAllocated;
  }

  bool get _isValid {
    return (_remaining.abs() < 0.01) &&
        _amountControllers.every((c) => (double.tryParse(c.text) ?? 0) > 0);
  }

  void _addSplitRow() {
    setState(() {
      final rem = _remaining > 0 ? _remaining : 0.0;
      final nextCat = _allCategories.firstWhere(
        (cat) => !_selectedCategories.contains(cat),
        orElse: () => 'General',
      );
      _selectedCategories.add(nextCat);
      _amountControllers
          .add(TextEditingController(text: rem.toStringAsFixed(0)));
    });
  }

  void _removeSplitRow(int index) {
    if (_amountControllers.length <= 2) return;
    setState(() {
      _amountControllers[index].dispose();
      _amountControllers.removeAt(index);
      _selectedCategories.removeAt(index);
    });
  }

  void _applyPercentagePreset(List<double> percentages) {
    if (percentages.length != _amountControllers.length) {
      // Re-create controllers to match percentages length
      setState(() {
        _clearControllers();
        for (int i = 0; i < percentages.length; i++) {
          final cat = i < _allCategories.length ? _allCategories[i] : 'General';
          _selectedCategories.add(cat);
          final amt = (widget.transaction.amount * (percentages[i] / 100))
              .roundToDouble();
          _amountControllers
              .add(TextEditingController(text: amt.toStringAsFixed(0)));
        }
      });
      return;
    }

    setState(() {
      for (int i = 0; i < percentages.length; i++) {
        final amt = (widget.transaction.amount * (percentages[i] / 100))
            .roundToDouble();
        _amountControllers[i].text = amt.toStringAsFixed(0);
      }
    });
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
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Split Transaction',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.transaction.merchant} • Total ${currency.format(widget.transaction.amount)}',
                      style: const TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: AppTheme.textMutedColor(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Smart Split Suggestion Banner (User Spec: Amazon ₹4,500 PaisaPilot detects...)
            if (_showSmartSuggestion && _smartSuggestion != null) ...[
              GlassCard(
                borderColor: AppTheme.purpleGlow.withOpacity(0.4),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: AppTheme.purpleGlow, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'SUGGESTED SMART SPLIT',
                          style: TextStyle(
                            color: AppTheme.purpleGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _smartSuggestion!
                          .map((s) =>
                              '${s.category}: ${currency.format(s.amount)}')
                          .join('  •  '),
                      style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.purpleGlow,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 34),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _applySmartSplit,
                          child: const Text('Apply Split',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showSmartSuggestion = false),
                          child: Text('Keep Single',
                              style: TextStyle(
                                  color: AppTheme.textMutedColor(context), fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Percentage Split Presets
            Text(
              'QUICK PERCENTAGE PRESETS',
              style: TextStyle(
                  color: AppTheme.textMutedColor(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip(context,
                      '50 / 50', () => _applyPercentagePreset([50, 50])),
                  const SizedBox(width: 8),
                  _buildPresetChip(context,
                      '70 / 30', () => _applyPercentagePreset([70, 30])),
                  const SizedBox(width: 8),
                  _buildPresetChip(context,
                      '60 / 40', () => _applyPercentagePreset([60, 40])),
                  const SizedBox(width: 8),
                  _buildPresetChip(context, '50 / 30 / 20',
                      () => _applyPercentagePreset([50, 30, 20])),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Itemized Split Categories List
            ...List.generate(_amountControllers.length, (index) {
              final amt =
                  double.tryParse(_amountControllers[index].text) ?? 0.0;
              final pct = widget.transaction.amount > 0
                  ? ((amt / widget.transaction.amount) * 100).toStringAsFixed(0)
                  : '0';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategories[index],
                        dropdownColor: AppTheme.cardColor(context),
                        style:
                            TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.cardColor(context),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppTheme.borderColor(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppTheme.borderColor(context)),
                          ),
                        ),
                        items: _allCategories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategories[index] = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Amount Field + Pct Badge
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _amountControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(
                              color: AppTheme.electricMint,
                              fontWeight: FontWeight.bold),
                          suffixText: '$pct%',
                          suffixStyle: TextStyle(
                              color: AppTheme.textMutedColor(context), fontSize: 11),
                          filled: true,
                          fillColor: AppTheme.cardColor(context),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppTheme.borderColor(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppTheme.borderColor(context)),
                          ),
                        ),
                      ),
                    ),

                    if (_amountControllers.length > 2) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            color: AppTheme.dangerCoral, size: 20),
                        onPressed: () => _removeSplitRow(index),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // ＋ Add Category Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.electricCyan,
                side: const BorderSide(color: AppTheme.electricCyan),
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('＋ Add Category Allocation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _addSplitRow,
            ),
            const SizedBox(height: 20),

            // Live Remaining Allocation Guard (User Spec: Total must equal original, show remaining live)
            GlassCard(
              borderColor: _remaining.abs() < 0.01
                  ? AppTheme.semanticSuccess
                  : AppTheme.dangerCoral,
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allocated Sum:',
                          style: TextStyle(
                              color: AppTheme.textMutedColor(context), fontSize: 11)),
                      Text(
                        '${currency.format(_totalAllocated)} / ${currency.format(widget.transaction.amount)}',
                        style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_remaining.abs() < 0.01
                              ? AppTheme.semanticSuccess
                              : AppTheme.dangerCoral)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _remaining.abs() < 0.01
                          ? '✓ Balanced (₹0 Remaining)'
                          : 'Remaining: ${currency.format(_remaining)}',
                      style: TextStyle(
                        color: _remaining.abs() < 0.01
                            ? AppTheme.semanticSuccess
                            : AppTheme.dangerCoral,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save Split Button (Disabled if remaining != 0)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isValid ? AppTheme.electricMint : (AppTheme.isDark(context) ? Colors.white12 : Colors.black12),
                  foregroundColor: _isValid ? Colors.white : AppTheme.textDisabledColor(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isValid
                    ? () {
                        final splits = <TransactionSplit>[];
                        for (int i = 0; i < _amountControllers.length; i++) {
                          final amt = double.parse(_amountControllers[i].text);
                          splits.add(TransactionSplit(
                            category: _selectedCategories[i],
                            amount: amt,
                          ));
                        }
                        widget.onSave(splits);
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Save Split Allocations',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, VoidCallback onTap) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.electricCyan.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: AppTheme.electricCyan,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      ),
    );
  }
}
