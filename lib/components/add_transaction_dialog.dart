import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../services/smart_rules_service.dart';
import '../family_engine/services/family_service.dart';
import '../theme/app_theme.dart';
import 'split_transaction_dialog.dart';
import '../models/transaction_draft.dart';
import '../services/canonical_ingestion_service.dart';

class AddTransactionDialog extends StatefulWidget {
  final TransactionItem? transactionToEdit;
  final TransactionType? initialType;
  final String? initialCategory;

  const AddTransactionDialog({
    super.key,
    this.transactionToEdit,
    this.initialType,
    this.initialCategory,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedCategory;
  late TransactionType _selectedType;
  late DateTime _selectedDate;
  bool _isShared = false;
  List<TransactionSplit>? _pendingSplits;

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;
    if (edit != null) {
      _amountController.text = edit.amount.toString();
      _merchantController.text = edit.merchant;
      _notesController.text = edit.notes ?? '';
      _selectedCategory = edit.category;
      _selectedType = edit.type;
      _selectedDate = edit.date;
      _isShared = edit.isShared;
      _pendingSplits = edit.splits;
    } else {
      _selectedCategory = widget.initialCategory ?? 'Food';
      _selectedType = widget.initialType ?? TransactionType.debit;
      _selectedDate = DateTime.now();
      _isShared = false;
    }
  }

  static const List<String> _categories = [
    'Food',
    'Fuel',
    'Shopping',
    'Medical',
    'Travel',
    'Entertainment',
    'Recharge',
    'Bills',
    'Rent',
    'EMI',
    'Salary',
    'Investments',
    'Gifts',
    'Education',
    'Personal Care',
    'Pets',
    'Donations',
    'Taxes',
    'Others',
    'General',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.electricCyan,
            onPrimary: Colors.black,
            surface: AppTheme.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(() => _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            now.hour,
            now.minute,
            now.second,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final surfaceColor = AppTheme.surfaceColor(context);
    final cardColor = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.transactionToEdit != null
                            ? 'Edit Transaction'
                            : 'Add Transaction',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Responsive Expense / Income Segmented Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'Expense',
                            sublabel: 'Debit',
                            icon: Icons.arrow_upward_rounded,
                            type: TransactionType.debit,
                            activeColor: AppTheme.semanticDanger,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSegmentButton(
                            label: 'Income',
                            sublabel: 'Credit',
                            icon: Icons.arrow_downward_rounded,
                            type: TransactionType.credit,
                            activeColor: AppTheme.semanticSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      labelStyle: TextStyle(color: textSecondary),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                        color: AppTheme.semanticInfo,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.semanticInfo)),
                    ),
                    validator: (val) {
                      if (val == null ||
                          val.isEmpty ||
                          (double.tryParse(val) ?? 0) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Merchant Field
                  TextFormField(
                    controller: _merchantController,
                    style: TextStyle(
                      color: textPrimary,
                      decoration: TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Merchant / Payee',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.semanticInfo)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter merchant name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: cardColor,
                    style: TextStyle(
                      color: textPrimary,
                      decoration: TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                          value: cat,
                          child: Text(cat,
                              style: const TextStyle(
                                  decoration: TextDecoration.none)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 6),

                  // ＋ Split Transaction Button & Pending Splits Display
                  if (_pendingSplits != null && _pendingSplits!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.purpleAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.call_split_rounded,
                              color: Colors.purpleAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Split Allocations Active:',
                                  style: TextStyle(
                                      color: Colors.purpleAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _pendingSplits!
                                      .map((s) =>
                                          '${s.category}: ₹${s.amount.toStringAsFixed(0)}')
                                      .join('  •  '),
                                  style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.semanticDanger, size: 18),
                            onPressed: () =>
                                setState(() => _pendingSplits = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          final amount =
                              double.tryParse(_amountController.text) ?? 0.0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter an amount before splitting categories.'),
                                backgroundColor: AppTheme.semanticWarning,
                              ),
                            );
                            return;
                          }

                          final tempTx = TransactionItem(
                            amount: amount,
                            merchant: _merchantController.text.trim().isEmpty
                                ? 'Merchant'
                                : _merchantController.text.trim(),
                            category: _selectedCategory,
                            type: _selectedType,
                            source: TransactionSource.manual,
                            date: _selectedDate,
                          );

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SplitTransactionDialog(
                              transaction: tempTx,
                              onSave: (splits) {
                                setState(() {
                                  _pendingSplits = splits;
                                  _selectedCategory =
                                      'Split (${splits.length} categories)';
                                });
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.call_split_rounded,
                            color: AppTheme.semanticInfo, size: 16),
                        label: const Text(
                          '＋ Split Transaction',
                          style: TextStyle(
                            color: AppTheme.semanticInfo,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Date Picker
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Transaction Date',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    decoration: TextDecoration.none,
                                  )),
                              const SizedBox(height: 3),
                              Text(
                                dateFormat.format(_selectedDate),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.calendar_today_outlined,
                              color: AppTheme.semanticInfo, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes Field
                  TextFormField(
                    controller: _notesController,
                    style: TextStyle(
                      color: textPrimary,
                      decoration: TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppTheme.cardBorder)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Share with Family Toggle
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isShared
                            ? AppTheme.electricMint.withOpacity(0.4)
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Share with Family',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        _isShared
                            ? 'Visible in Family Workspace summary'
                            : 'Private to your active profile only',
                        style: TextStyle(
                          color:
                              _isShared ? AppTheme.electricMint : textSecondary,
                          fontSize: 11.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      value: _isShared,
                      activeColor: AppTheme.electricMint,
                      onChanged: (val) => setState(() => _isShared = val),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.semanticInfo,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _submit,
                      child: const Text('Save Transaction',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required TransactionType type,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? activeColor : AppTheme.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? activeColor : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    sublabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? activeColor.withOpacity(0.8)
                          : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final messenger = ScaffoldMessenger.of(context);
      final surfaceColor = AppTheme.surfaceColor(context);
      final textPrimary = AppTheme.textPrimaryColor(context);
      final navigator = Navigator.of(context);

      final amount = double.parse(_amountController.text);
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      final previousBudget = provider.dailySafeSpendingLimit;

      final edit = widget.transactionToEdit;
      final effectiveCat = _pendingSplits != null && _pendingSplits!.isNotEmpty
          ? 'Split (${_pendingSplits!.length} categories)'
          : _selectedCategory;

      final activeProfileId = await FamilyService.instance.getActiveProfileId();

      final item = TransactionItem(
        id: edit?.id,
        amount: amount,
        merchant: _merchantController.text.trim(),
        category: effectiveCat,
        type: _selectedType,
        source: edit?.source ?? TransactionSource.manual,
        date: _selectedDate,
        account: edit?.account,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        rawSms: edit?.rawSms,
        splits: _pendingSplits,
        profileId: edit?.profileId ?? activeProfileId,
        isShared: _isShared,
        originalCategory:
            edit?.originalCategory ?? edit?.category ?? effectiveCat,
        userCategory: effectiveCat,
      );

      if (edit != null) {
        await provider.updateTransaction(item);
        if (_selectedCategory != edit.category) {
          await SmartRulesService().learnRule(item.merchant, _selectedCategory);
        }
      } else {
        final draft = TransactionDraft.fromTransactionItem(item);
        final preview = await CanonicalIngestionService.instance.previewSingle(
          draft: draft,
          profileId: activeProfileId,
        );

        if ((preview.isDuplicate ||
                preview.suggestedAction == IngestionAction.needsReview) &&
            preview.matchedExistingTransaction != null) {
          if (!mounted) return;
          final ex = preview.matchedExistingTransaction!;
          final action = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warningAmber, size: 24),
                  SizedBox(width: 8),
                  Text('Possible Duplicate',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A matching transaction already exists:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ex.merchant} • ₹${ex.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Source: ${ex.displaySource} • ${DateFormat('dd MMM yyyy').format(ex.date)}',
                          style: const TextStyle(
                              color: AppTheme.electricCyan, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Do you want to keep both as separate transactions, or merge them into one canonical event?',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'merge'),
                  child: const Text('Merge',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 'keep_both'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricMint,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Keep Both',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          if (action == 'cancel' || action == null) {
            return;
          }
          if (action == 'keep_both') {
            await provider.addTransaction(item, allowAutoMerge: false);
          } else if (action == 'merge') {
            await provider.addTransaction(item, allowAutoMerge: true);
          }
        } else {
          await provider.addTransaction(item);
        }
      }

      final remainingBudget = (previousBudget - amount).clamp(0.0, 500000.0);

      if (mounted) {
        navigator.pop(true);

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: surfaceColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.semanticSuccess, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    edit != null
                        ? '✓ Updated ${item.merchant}. Safe Today: ₹${remainingBudget.toStringAsFixed(0)}'
                        : '✓ Added ${item.merchant}. Safe Today: ₹${remainingBudget.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppTheme.semanticInfo,
              onPressed: () async {
                await provider.undoLastAction();
              },
            ),
          ),
        );
      }
    }
  }
}
