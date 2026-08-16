import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/budget_forecast.dart';
import '../models/savings_goal.dart';
import '../models/upcoming_bill.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/gradient_text.dart';
import '../components/money_coach_card.dart';
import '../components/savings_goals_card.dart';
import '../components/bill_reminders_card.dart';
import '../components/spending_heatmap_widget.dart';
import '../components/animated_scale_button.dart';
import '../services/money_coach_service.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final forecast = provider.budgetForecast;
        final categoryBreakdown = provider.categoryBreakdown;
        final monthlyBudget = provider.monthlyBudget;
        final monthSpend = provider.monthSpend;
        final transactions = provider.transactions;
        final savingsGoals = provider.savingsGoals;
        final upcomingBills = provider.upcomingBills;

        // Real Data Money Coach Tips
        final coachTips = MoneyCoachService.generateTips(
          transactions: transactions,
          monthlyBudget: monthlyBudget,
          monthSpend: monthSpend,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GradientText(
                    'Budget Engine',
                    gradient: AppTheme.primaryGradient,
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  AnimatedScaleButton(
                    onTap: () => _showBudgetEditDialog(context, provider),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit_outlined,
                          color: AppTheme.electricCyan, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Velocity pacing & overspending forecast radar',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),

              // 1. Velocity Radar Hero Card — only shown when user has set a budget
              if (!provider.hasBudget)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded,
                              color: AppTheme.electricCyan, size: 20),
                          const SizedBox(width: 10),
                          Text('No Monthly Budget Set',
                              style: TextStyle(
                                  color: AppTheme.textPrimaryColor(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Set a monthly budget to enable velocity tracking, overspending forecasts, and daily Safe Today limits.',
                        style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 13,
                            height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      AnimatedScaleButton(
                        onTap: () => _showBudgetEditDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.electricCyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.electricCyan.withOpacity(0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: AppTheme.electricCyan, size: 16),
                              SizedBox(width: 8),
                              Text('Set Monthly Budget',
                                  style: TextStyle(
                                      color: AppTheme.electricCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Predicted Month-End Spend',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currencyFormat.format(forecast.predictedMonthEnd),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: forecast.isOverBudget
                                  ? AppTheme.dangerCoral
                                  : AppTheme.electricCyan,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          _buildRiskChip(forecast.riskLevel),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildForecastDetail('Monthly Target',
                              currencyFormat.format(monthlyBudget)),
                          _buildForecastDetail('Spent So Far',
                              currencyFormat.format(monthSpend)),
                          _buildForecastDetail('Daily Velocity',
                              '${currencyFormat.format(forecast.dailyVelocity)}/day'),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),

              // 2. 💡 Money Coach Tip Card
              MoneyCoachCard(tips: coachTips),
              const SizedBox(height: 18),

              // 3. 🎯 Real User Savings Goals (Zero Fake Data)
              SavingsGoalsCard(
                goals: savingsGoals,
                onAddGoal: () => _showAddGoalDialog(context, provider),
              ),
              const SizedBox(height: 18),

              // 4. 📅 Real User Fixed Expenses — wrapped in Material for PopupMenuButton
              Material(
                type: MaterialType.transparency,
                child: BillRemindersCard(
                  bills: upcomingBills,
                  onAddBill: () => _showAddBillDialog(context, provider),
                  onEditBill: (bill) =>
                      _showEditBillDialog(context, provider, bill),
                  onTogglePause: (bill) =>
                      provider.toggleUpcomingBillActive(bill.id),
                  onDeleteBill: (id) => provider.deleteUpcomingBill(id),
                ),
              ),
              const SizedBox(height: 18),

              // 5. 🟩 GitHub-Style Spending Heatmap
              SpendingHeatmapWidget(transactions: transactions),
              const SizedBox(height: 18),

              // 6. Category Spend Breakdown
              Text('Category Spend Breakdown',
                  style: TextStyle(
                      color: AppTheme.textPrimaryColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (categoryBreakdown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No spending recorded this month yet.',
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor(context))),
                )
              else
                ...categoryBreakdown.entries.map((entry) {
                  final catSpent = entry.value;
                  final pct =
                      monthlyBudget > 0 ? (catSpent / monthlyBudget) : 0.0;
                  final pctClamped = pct.clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key,
                                  style: TextStyle(
                                      color: AppTheme.textPrimaryColor(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(
                                currencyFormat.format(catSpent),
                                style: const TextStyle(
                                    color: AppTheme.electricCyan,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pctClamped,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.electricCyan),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskChip(RiskLevel risk) {
    String text = 'Low Risk';
    Color col = AppTheme.successGreen;

    if (risk == RiskLevel.high) {
      text = 'High Risk';
      col = AppTheme.dangerCoral;
    } else if (risk == RiskLevel.moderate) {
      text = 'Moderate Risk';
      col = AppTheme.warningAmber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: col.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withOpacity(0.4)),
      ),
      child: Text(text,
          style:
              TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildForecastDetail(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  void _showAddGoalDialog(BuildContext context, BudgetProvider provider) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Add Real Savings Goal',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Goal Title (e.g. Emergency Fund)',
                  labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Target Amount (₹)',
                  labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Current Saved Amount (₹)',
                  labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black),
            onPressed: () async {
              final title = titleController.text.trim();
              final target = double.tryParse(targetController.text) ?? 0.0;
              final current = double.tryParse(currentController.text) ?? 0.0;

              if (title.isEmpty || target <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Please enter a valid title and target amount.')),
                );
                return;
              }
              Navigator.pop(ctx);
              await provider.addSavingsGoal(SavingsGoal(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                targetAmount: target,
                currentAmount: current,
                targetDate: DateTime.now().add(const Duration(days: 180)),
                emoji: '💰',
              ));
              titleController.dispose();
              targetController.dispose();
              currentController.dispose();
            },
            child: const Text('Add Goal'),
          ),
        ],
      ),
    ).then((_) {
      // Ensure dispose even on dialog dismiss without save
      if (titleController.text.isEmpty) {
        titleController.dispose();
        targetController.dispose();
        currentController.dispose();
      }
    });
  }

  void _showAddBillDialog(BuildContext context, BudgetProvider provider) {
    _showFixedExpenseFormDialog(context, provider: provider, existing: null);
  }

  void _showEditBillDialog(
      BuildContext context, BudgetProvider provider, UpcomingBill existing) {
    _showFixedExpenseFormDialog(context,
        provider: provider, existing: existing);
  }

  void _showFixedExpenseFormDialog(
    BuildContext context, {
    required BudgetProvider provider,
    UpcomingBill? existing,
  }) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');

    String selectedFrequency = existing?.frequency ?? 'Monthly';
    String selectedCategory = existing?.category ?? 'Housing';
    String selectedAccount = existing?.account ?? 'SBI';
    int selectedDueDay = existing?.dueDate.day ?? 5;
    bool isActive = existing?.isActive ?? true;

    final emojis = {
      'Housing': '🏠',
      'Utilities': '⚡',
      'Mobile & Internet': '📱',
      'Education': '🎓',
      'Subscription': '🍿',
      'Other': '📄',
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'Edit Fixed Expense' : 'Add Fixed Expense',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Expense Name (e.g. Rent, Mobile)',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                            color: AppTheme.secondaryEmerald,
                            fontWeight: FontWeight.bold),
                        labelText: 'Amount (₹)',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Frequency Selector
                    const Text('Frequency',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      dropdownColor: AppTheme.darkCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['Monthly', 'Weekly', 'Yearly', 'Custom']
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedFrequency = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Due Day Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Due Date',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                        DropdownButton<int>(
                          value: selectedDueDay.clamp(1, 31),
                          dropdownColor: AppTheme.darkCard,
                          style: const TextStyle(
                              color: AppTheme.secondaryEmerald,
                              fontWeight: FontWeight.bold),
                          items: List.generate(31, (i) => i + 1)
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text('${d}th of month'),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedDueDay = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Category Selector
                    const Text('Category',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: AppTheme.darkCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        'Housing',
                        'Utilities',
                        'Mobile & Internet',
                        'Education',
                        'Subscription',
                        'Other'
                      ]
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${emojis[c]} $c'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Account Selector
                    const Text('Account',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedAccount,
                      dropdownColor: AppTheme.darkCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['SBI', 'HDFC', 'ICICI', 'Axis', 'Cash', 'Wallet']
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(a),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedAccount = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Active Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active (Include in Safe Today)',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                        Switch(
                          value: isActive,
                          activeColor: AppTheme.secondaryEmerald,
                          onChanged: (val) => setState(() => isActive = val),
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
                    backgroundColor: AppTheme.secondaryEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text) ?? 0.0;

                    if (name.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter a valid expense name and amount.')),
                      );
                      return;
                    }

                    final now = DateTime.now();
                    final dueDate =
                        DateTime(now.year, now.month, selectedDueDay);

                    final emoji = emojis[selectedCategory] ?? '🏠';

                    final updated = UpcomingBill(
                      id: existing?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      title: name,
                      amount: amount,
                      dueDate: dueDate,
                      providerEmoji: emoji,
                      category: selectedCategory,
                      account: selectedAccount,
                      frequency: selectedFrequency,
                      isActive: isActive,
                      isPaid: existing?.isPaid ?? false,
                    );

                    Navigator.pop(ctx);

                    if (isEditing) {
                      await provider.updateUpcomingBill(updated);
                    } else {
                      await provider.addUpcomingBill(updated);
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBudgetEditDialog(BuildContext context, BudgetProvider provider) {
    final controller =
        TextEditingController(text: provider.monthlyBudget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: const Text('Set Monthly Income / Budget Target',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              prefixStyle:
                  TextStyle(color: AppTheme.electricCyan, fontSize: 18),
              labelText: 'Monthly Income / Limit (₹)',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
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
                  foregroundColor: Colors.black),
              onPressed: () {
                final newBudget = double.tryParse(controller.text);
                if (newBudget != null && newBudget >= 0) {
                  provider.updateMonthlyBudget(newBudget);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
