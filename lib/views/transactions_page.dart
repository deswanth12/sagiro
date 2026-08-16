import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import '../components/add_transaction_dialog.dart';
import '../components/sms_scan_result_sheet.dart';
import '../components/financial_calendar_widget.dart';
import 'csv_import_page.dart';
import 'import_center_page.dart';
import 'settings_page.dart';
import '../utils/month_range.dart';

import '../components/split_transaction_dialog.dart';
import '../components/multi_category_filter_sheet.dart';
import '../components/transaction_detail_sheet.dart';
import '../components/quick_add_modal_sheet.dart';

/// Wrapper Data Models for Timeline Feed
class MonthHeaderItem {
  final String key;
  final String monthName;
  final double totalIncome;
  final double totalExpense;
  final double netCashflow;
  final int count;
  final Map<String, double> categoryBreakdown;
  final bool isExpanded;

  MonthHeaderItem({
    required this.key,
    required this.monthName,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
    required this.count,
    required this.categoryBreakdown,
    required this.isExpanded,
  });
}

class WeekHeaderItem {
  final String key;
  final String title;
  final double spent;
  final int count;
  final bool isExpanded;

  WeekHeaderItem({
    required this.key,
    required this.title,
    required this.spent,
    required this.count,
    required this.isExpanded,
  });
}

class DayHeaderItem {
  final String title;
  final DateTime date;

  DayHeaderItem({required this.title, required this.date});
}

class MilestoneEventItem {
  final String title;
  final String subtitle;
  final Color color;

  MilestoneEventItem(
      {required this.title, required this.subtitle, required this.color});
}

class TransactionItemWrapper {
  final TransactionItem tx;

  TransactionItemWrapper({required this.tx});
}

/// TransactionsPage — Timeline Screen (Emotion: UNDERSTANDING).
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  String _selectedYear = 'All';
  String _activeSmartFilter = 'All';
  String _searchQuery = '';
  Set<String> _selectedMultiCategories = {};
  final Set<String> _expandedMonths = {};
  final Set<String> _expandedWeeks = {};

  final List<String> _smartFilters = const [
    'All',
    'This Month',
    'Last Month',
    'Last 90 Days',
    'Income',
    'Expense',
    'Bills',
    'Food',
    'Shopping',
    'Transport',
    'Subscriptions',
    'SMS',
    'Manual',
    'CSV'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, "0")}';
    _expandedMonths.add(currentMonthKey);
    _expandedWeeks.add('$currentMonthKey-W1');
    _expandedWeeks.add('$currentMonthKey-W2');
    _expandedWeeks.add('$currentMonthKey-W3');
    _expandedWeeks.add('$currentMonthKey-W4');
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.backgroundColor(context);
    final surfaceColor = AppTheme.surfaceColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final allTx = provider.transactions;
        final filteredTx = _applyFilters(allTx, provider.monthlyBudget);
        final availableYears = _getAvailableYears(allTx);
        final groupedData = _groupTransactions(filteredTx);

        return Scaffold(
          backgroundColor: bgColor,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.electricCyan,
            foregroundColor: Colors.black,
            elevation: 4,
            onPressed: () {
              AppTheme.triggerHaptic(HapticFeedbackType.selection);
              _showQuickAddSheet(context);
            },
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Timeline',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${filteredTx.length} items logged • Complete clarity',
                            style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                letterSpacing: -0.1),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        initialValue: _selectedYear,
                        onSelected: (year) {
                          AppTheme.triggerHaptic(HapticFeedbackType.selection);
                          setState(() => _selectedYear = year);
                        },
                        color: surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.cardBorder),
                        ),
                        itemBuilder: (context) {
                          return ['All', ...availableYears].map((yr) {
                            return PopupMenuItem<String>(
                              value: yr,
                              child: Row(
                                children: [
                                  Icon(
                                    yr == _selectedYear
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: yr == _selectedYear
                                        ? AppTheme.semanticInfo
                                        : textSecondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    yr == 'All' ? 'All Years' : yr,
                                    style: TextStyle(
                                      color: yr == _selectedYear
                                          ? AppTheme.semanticInfo
                                          : textPrimary,
                                      fontWeight: yr == _selectedYear
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedYear == 'All'
                                    ? 'Years'
                                    : _selectedYear,
                                style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.semanticInfo, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedScaleButton(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsPage()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Icon(Icons.settings_rounded,
                              color: textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Financial Calendar™ Embedded Banner
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: FinancialCalendarWidget(
                    monthlyBudget: provider.monthlyBudget,
                    monthSpend: provider.monthSpend,
                    upcomingBills: provider.upcomingBills,
                    transactions: provider.transactions,
                    onAddTransaction: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddTransactionDialog(),
                      );
                    },
                    onAddRecurringExpense: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const QuickAddModalSheet(),
                      );
                    },
                  ),
                ),

                // 3. Search Field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'Search merchant, category, amount (e.g. Swiggy, ₹500)...',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.semanticInfo, size: 20),
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  ),
                ),

                // 4. Smart Filter Chips & Multi-Category Filter
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    children: [
                      // Multi-Category Filter Trigger Chip
                      AnimatedScaleButton(
                        onTap: () {
                          MultiCategoryFilterSheet.show(
                            context,
                            transactions: allTx,
                            initialSelectedCategories: _selectedMultiCategories,
                            onApplyFilter: (selected) {
                              setState(
                                  () => _selectedMultiCategories = selected);
                            },
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedMultiCategories.isNotEmpty
                                ? AppTheme.semanticInfo.withOpacity(0.2)
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedMultiCategories.isNotEmpty
                                  ? AppTheme.semanticInfo
                                  : AppTheme.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                color: _selectedMultiCategories.isNotEmpty
                                    ? AppTheme.semanticInfo
                                    : textSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _selectedMultiCategories.isEmpty
                                    ? 'Multi-Category'
                                    : 'Filter (${_selectedMultiCategories.length})',
                                style: TextStyle(
                                  color: _selectedMultiCategories.isNotEmpty
                                      ? AppTheme.semanticInfo
                                      : textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      ..._smartFilters.map((filter) {
                        final isSelected = _activeSmartFilter == filter &&
                            _selectedMultiCategories.isEmpty;
                        return AnimatedScaleButton(
                          onTap: () {
                            AppTheme.triggerHaptic(
                                HapticFeedbackType.selection);
                            setState(() {
                              _activeSmartFilter = filter;
                              _selectedMultiCategories.clear();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.semanticInfo.withOpacity(0.15)
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.semanticInfo
                                    : AppTheme.cardBorder,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.semanticInfo
                                    : textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Multi-Category Live Banner (User Spec: Food + Fuel + Transport = ₹12,840)
                if (_selectedMultiCategories.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.electricMint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.electricMint.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MULTI-CATEGORY COMBINED TOTAL',
                                  style: TextStyle(
                                      color: AppTheme.electricMint,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedMultiCategories.join(" + ")} = ₹${filteredTx.where((t) => t.type == TransactionType.debit).fold<double>(0.0, (s, t) => s + t.amount).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.electricMint, size: 18),
                            onPressed: () => setState(
                                () => _selectedMultiCategories.clear()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // 5. Financial Timeline Feed
                Expanded(
                  child: filteredTx.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                          itemCount: groupedData.length,
                          itemBuilder: (context, index) {
                            final item = groupedData[index];
                            if (item is MonthHeaderItem) {
                              return _buildMonthSummaryCard(
                                  context, item, provider.monthlyBudget);
                            } else if (item is WeekHeaderItem) {
                              return _buildWeekSummaryHeader(item);
                            } else if (item is DayHeaderItem) {
                              return _buildDayHeader(item);
                            } else if (item is MilestoneEventItem) {
                              return _buildMilestoneEventCard(item);
                            } else if (item is TransactionItemWrapper) {
                              return _buildSwipeableTransactionTile(
                                  context, item.tx, provider);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helper Data Filtering & Grouping Logic ─────────────────────────

  List<String> _getAvailableYears(List<TransactionItem> list) {
    final years = list.map((t) => t.date.year.toString()).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years.isEmpty ? [DateTime.now().year.toString()] : years;
  }

  List<TransactionItem> _applyFilters(
      List<TransactionItem> list, double monthlyBudget) {
    return list.where((t) {
      if (_selectedYear != 'All' && t.date.year.toString() != _selectedYear) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final dateStr =
            DateFormat('MMMM yyyy d MMM').format(t.date).toLowerCase();
        final matchesMerchant = t.merchant.toLowerCase().contains(q);
        final matchesCategory = t.category.toLowerCase().contains(q);
        final matchesAmount = t.amount.toStringAsFixed(0).contains(q);
        final matchesDate = dateStr.contains(q);

        if (!matchesMerchant &&
            !matchesCategory &&
            !matchesAmount &&
            !matchesDate) {
          return false;
        }
      }

      if (_selectedMultiCategories.isNotEmpty) {
        if (t.isSplit) {
          final match = t.splits!
              .any((s) => _selectedMultiCategories.contains(s.category));
          if (!match) return false;
        } else {
          if (!_selectedMultiCategories.contains(t.category)) return false;
        }
      }

      if (_activeSmartFilter == 'This Month') {
        return MonthRange.current().contains(t.date);
      }
      if (_activeSmartFilter == 'Last Month') {
        return MonthRange.previous().contains(t.date);
      }
      if (_activeSmartFilter == 'Last 90 Days') {
        return DateTime.now().difference(t.date).inDays <= 90;
      }
      if (_activeSmartFilter == 'Income') {
        return t.type == TransactionType.credit;
      }
      if (_activeSmartFilter == 'Expense') {
        return t.type == TransactionType.debit;
      }
      if (_activeSmartFilter == 'SMS') {
        return t.source == TransactionSource.sms;
      }
      if (_activeSmartFilter == 'Manual') {
        return t.source == TransactionSource.manual;
      }
      if (_activeSmartFilter == 'CSV') {
        return t.source == TransactionSource.csv;
      }
      if (_activeSmartFilter == 'Bills') {
        return t.category.toLowerCase().contains('emi') ||
            t.category.toLowerCase().contains('rent') ||
            t.category.toLowerCase().contains('recharge');
      }
      if (_activeSmartFilter == 'Food') {
        return t.category.toLowerCase().contains('food');
      }
      if (_activeSmartFilter == 'Shopping') {
        return t.category.toLowerCase().contains('shopping');
      }
      if (_activeSmartFilter == 'Transport') {
        return t.category.toLowerCase().contains('fuel') ||
            t.category.toLowerCase().contains('travel');
      }
      if (_activeSmartFilter == 'Subscriptions') {
        return t.category.toLowerCase().contains('entertainment');
      }

      return true;
    }).toList();
  }

  List<dynamic> _groupTransactions(List<TransactionItem> txList) {
    final List<dynamic> result = [];
    if (txList.isEmpty) return result;

    final Map<String, List<TransactionItem>> monthGroups = {};
    for (final tx in txList) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, "0")}';
      monthGroups.putIfAbsent(key, () => []).add(tx);
    }

    final sortedMonthKeys = monthGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final mKey in sortedMonthKeys) {
      final mTransactions = monthGroups[mKey]!;
      final firstTxDate = mTransactions.first.date;

      double incomeSum = 0;
      double expenseSum = 0;
      final Map<String, double> catBreakdown = {};

      for (final t in mTransactions) {
        if (t.type == TransactionType.credit) {
          incomeSum += t.amount;
        } else {
          expenseSum += t.amount;
          catBreakdown[t.category] = (catBreakdown[t.category] ?? 0) + t.amount;
        }
      }

      final isExpanded = _expandedMonths.contains(mKey);

      result.add(MonthHeaderItem(
        key: mKey,
        monthName: DateFormat('MMMM yyyy').format(firstTxDate),
        totalIncome: incomeSum,
        totalExpense: expenseSum,
        netCashflow: incomeSum - expenseSum,
        count: mTransactions.length,
        categoryBreakdown: catBreakdown,
        isExpanded: isExpanded,
      ));

      if (isExpanded) {
        final Map<String, List<TransactionItem>> weekGroups = {};
        for (final tx in mTransactions) {
          final weekNum = ((tx.date.day - 1) ~/ 7) + 1;
          final wKey = '$mKey-W$weekNum';
          weekGroups.putIfAbsent(wKey, () => []).add(tx);
        }

        final sortedWeekKeys = weekGroups.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        for (final wKey in sortedWeekKeys) {
          final wTransactions = weekGroups[wKey]!;
          final weekNum = wKey.split('-W').last;
          final weekSpent = wTransactions
              .where((t) => t.type == TransactionType.debit)
              .fold<double>(0, (s, t) => s + t.amount);
          final isWeekExpanded = _expandedWeeks.contains(wKey);

          result.add(WeekHeaderItem(
            key: wKey,
            title: 'Week $weekNum',
            spent: weekSpent,
            count: wTransactions.length,
            isExpanded: isWeekExpanded,
          ));

          if (isWeekExpanded) {
            final Map<String, List<TransactionItem>> dayGroups = {};
            for (final tx in wTransactions) {
              final dKey = DateFormat('yyyy-MM-dd').format(tx.date);
              dayGroups.putIfAbsent(dKey, () => []).add(tx);
            }

            final sortedDayKeys = dayGroups.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            for (final dKey in sortedDayKeys) {
              final dTransactions = dayGroups[dKey]!;
              final dDate = dTransactions.first.date;
              final dayLabel = _getFormatDayLabel(dDate);

              result.add(DayHeaderItem(title: dayLabel, date: dDate));

              for (final tx in dTransactions) {
                if (tx.type == TransactionType.credit && tx.amount >= 20000) {
                  result.add(MilestoneEventItem(
                    title: '🏆 Salary / Major Credit Received',
                    subtitle:
                        '₹${tx.amount.toStringAsFixed(0)} credited from ${tx.merchant}',
                    color: AppTheme.semanticSuccess,
                  ));
                }

                result.add(TransactionItemWrapper(tx: tx));
              }
            }
          }
        }
      }
    }

    return result;
  }

  String _getFormatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    if (target == yesterday) return 'Yesterday';
    return DateFormat('EEEE, d MMM').format(date);
  }

  // ── Render Widgets ──────────────────────────────────────────────────

  Widget _buildMonthSummaryCard(
      BuildContext context, MonthHeaderItem item, double monthlyBudget) {
    final budgetPercent = (monthlyBudget > 0)
        ? (item.totalExpense / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        borderColor: item.isExpanded
            ? AppTheme.semanticInfo.withOpacity(0.4)
            : AppTheme.crispBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                AppTheme.triggerHaptic(HapticFeedbackType.selection);
                setState(() {
                  if (item.isExpanded) {
                    _expandedMonths.remove(item.key);
                  } else {
                    _expandedMonths.add(item.key);
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          color: AppTheme.semanticInfo, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        item.monthName,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.crispBorder),
                        ),
                        child: Text(
                          '${item.count} Txns',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        item.isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.semanticInfo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricCol(
                    'INCOME',
                    '₹${item.totalIncome.toStringAsFixed(0)}',
                    AppTheme.semanticIncome),
                _buildMetricCol(
                    'EXPENSE',
                    '₹${item.totalExpense.toStringAsFixed(0)}',
                    AppTheme.semanticDanger),
                _buildMetricCol(
                  'NET CASHFLOW',
                  '${item.netCashflow >= 0 ? "+" : ""}₹${item.netCashflow.toStringAsFixed(0)}',
                  item.netCashflow >= 0
                      ? AppTheme.semanticSuccess
                      : AppTheme.semanticDanger,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budgetPercent,
                minHeight: 5,
                backgroundColor: AppTheme.darkSurface,
                valueColor: AlwaysStoppedAnimation<Color>(budgetPercent > 0.85
                    ? AppTheme.semanticDanger
                    : AppTheme.semanticInfo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String title, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(val,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }

  Widget _buildWeekSummaryHeader(WeekHeaderItem item) {
    return InkWell(
      onTap: () {
        AppTheme.triggerHaptic(HapticFeedbackType.selection);
        setState(() {
          if (item.isExpanded) {
            _expandedWeeks.remove(item.key);
          } else {
            _expandedWeeks.add(item.key);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.crispBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                    item.isExpanded
                        ? Icons.folder_open_outlined
                        : Icons.folder_outlined,
                    color: AppTheme.semanticInfo,
                    size: 16),
                const SizedBox(width: 8),
                Text(item.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('• ${item.count} items',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
            Row(
              children: [
                Text('₹${item.spent.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppTheme.semanticWarning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(width: 6),
                Icon(item.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textMuted, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader(DayHeaderItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        item.title,
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildMilestoneEventCard(MilestoneEventItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: item.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        color: item.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeableTransactionTile(
      BuildContext context, TransactionItem tx, BudgetProvider provider) {
    final isDebit = tx.type == TransactionType.debit;
    final formattedDate = DateFormat('h:mm a').format(tx.date);

    return Dismissible(
      key: Key('tx_${tx.id}_${tx.date.millisecondsSinceEpoch}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
            color: AppTheme.semanticInfo.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16)),
        child: const Row(
          children: [
            Icon(Icons.edit_outlined, color: AppTheme.semanticInfo, size: 18),
            SizedBox(width: 6),
            Text('Edit Category',
                style: TextStyle(
                    color: AppTheme.semanticInfo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: AppTheme.semanticDanger.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete',
                style: TextStyle(
                    color: AppTheme.semanticDanger,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded,
                color: AppTheme.semanticDanger, size: 18),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          if (tx.id != null) {
            AppTheme.triggerHaptic(HapticFeedbackType.medium);
            await provider.deleteTransaction(tx.id!);
          }
          return true;
        } else {
          _showCategoryEditorDialog(context, provider, tx);
          return false;
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AnimatedScaleButton(
          onTap: () {
            TransactionDetailSheet.show(context, tx);
          },
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      _getCategoryColor(tx.category).withOpacity(0.12),
                  child: Icon(_getCategoryIcon(tx.category),
                      color: _getCategoryColor(tx.category), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.merchant,
                        style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (tx.isSplit) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.purpleGlow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color:
                                        AppTheme.purpleGlow.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.call_split_rounded,
                                      color: AppTheme.purpleGlow, size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Split (${tx.splits!.length})',
                                    style: const TextStyle(
                                        color: AppTheme.purpleGlow,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else ...[
                            Text(
                              tx.category,
                              style: TextStyle(
                                  color: AppTheme.textSecondaryColor(context),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const Text(' • ',
                              style: TextStyle(color: AppTheme.textMuted)),
                          Text(formattedDate,
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${isDebit ? "-" : "+"}₹${NumberFormat.currency(symbol: '', decimalDigits: 0, locale: 'en_IN').format(tx.amount)}',
                      style: TextStyle(
                        color: isDebit
                            ? AppTheme.textPrimaryColor(context)
                            : AppTheme.semanticSuccess,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDebit
                                ? AppTheme.semanticDanger
                                : AppTheme.semanticSuccess)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDebit ? 'Expense' : 'Income',
                        style: TextStyle(
                          color: isDebit
                              ? AppTheme.semanticDanger
                              : AppTheme.semanticSuccess,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasActiveFilter = _searchQuery.isNotEmpty ||
        _selectedMultiCategories.isNotEmpty ||
        _activeSmartFilter != 'All' ||
        _selectedYear != 'All';

    if (hasActiveFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.semanticMuted.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded,
                    color: AppTheme.textSecondary, size: 40),
              ),
              const SizedBox(height: 18),
              const Text(
                'No matching transactions found.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting your search keywords, clearing category filters, or selecting a different date range.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkCard,
                  foregroundColor: AppTheme.electricCyan,
                  side: const BorderSide(color: AppTheme.electricCyan),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Clear All Filters',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  AppTheme.triggerHaptic(HapticFeedbackType.light);
                  setState(() {
                    _searchQuery = '';
                    _selectedMultiCategories.clear();
                    _activeSmartFilter = 'All';
                    _selectedYear = 'All';
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: AppTheme.semanticInfo.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.auto_stories_rounded,
                    color: AppTheme.semanticInfo, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'No financial events yet.',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Import a bank statement to build your financial timeline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textSecondary, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.semanticInfo,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Expense',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddTransactionDialog(),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Import Bank Statement',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ImportCenterPage()));
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.semanticInfo,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Import CSV',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CsvImportPage()));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose how you want to record your transaction',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              _buildActionTile(
                context: ctx,
                icon: Icons.edit_note_rounded,
                iconColor: AppTheme.electricCyan,
                title: 'Manual Expense',
                subtitle: 'Add expense or income manually',
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddTransactionDialog(),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                context: ctx,
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppTheme.electricMint,
                title: 'Bank Statement',
                subtitle: 'Import PDF, Excel, or camera OCR',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportCenterPage()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                context: ctx,
                icon: Icons.document_scanner_outlined,
                iconColor: AppTheme.semanticSuccess,
                title: 'Scan Bank SMS',
                subtitle: 'Auto-scan bank transaction SMS',
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const SmsScanResultSheet(),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                context: ctx,
                icon: Icons.file_upload_outlined,
                iconColor: AppTheme.semanticWarning,
                title: 'Import CSV',
                subtitle: 'Import CSV or text statements',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CsvImportPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCategoryEditorDialog(
      BuildContext context, BudgetProvider provider, TransactionItem tx) {
    final List<String> opts = [
      'Food',
      'Fuel',
      'Shopping',
      'EMI',
      'Rent',
      'Medical',
      'Travel',
      'Entertainment',
      'Recharge',
      'Investment',
      'Salary',
      'General'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.crispBorder)),
          title: Text('Edit Category: ${tx.merchant}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Smart Rules will auto-remember this category for future transactions!',
                  style: TextStyle(color: AppTheme.semanticInfo, fontSize: 12)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: opts.map((cat) {
                  final isSelected = tx.category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.semanticInfo,
                    labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal),
                    onSelected: (_) {
                      AppTheme.triggerHaptic(HapticFeedbackType.light);
                      final updated = tx.copyWith(
                          category: cat, userCategory: cat, splits: null);
                      provider.updateTransaction(updated);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.electricCyan,
                  side: const BorderSide(color: AppTheme.electricCyan),
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.call_split_rounded, size: 18),
                label: Text(
                  tx.isSplit
                      ? 'Edit Category Splits'
                      : '⚡ Split Transaction Categories',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SplitTransactionDialog(
                      transaction: tx,
                      onSave: (splits) async {
                        final updated = tx.copyWith(
                          category: 'Split (${splits.length} categories)',
                          splits: splits,
                        );
                        await provider.updateTransaction(updated);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'emi':
        return Icons.account_balance_rounded;
      case 'rent':
        return Icons.home_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'recharge':
        return Icons.phone_android_rounded;
      case 'investment':
        return Icons.show_chart_rounded;
      case 'salary':
        return Icons.payments_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return AppTheme.semanticDanger;
      case 'fuel':
        return AppTheme.semanticWarning;
      case 'shopping':
        return AppTheme.semanticInfo;
      case 'travel':
        return AppTheme.semanticInfo;
      case 'entertainment':
        return Colors.pinkAccent;
      case 'salary':
        return AppTheme.semanticSuccess;
      default:
        return AppTheme.semanticMuted;
    }
  }
}
