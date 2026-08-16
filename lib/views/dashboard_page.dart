import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../providers/authentication_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import '../components/quick_add_modal_sheet.dart';
import '../components/why_safe_today_sheet.dart';
import '../components/transaction_detail_sheet.dart';
import '../components/sms_scan_result_sheet.dart';
import '../components/add_transaction_dialog.dart';
import '../components/voice_expense_sheet.dart';
import '../providers/settings_provider.dart';
import '../services/app_settings_service.dart';
import 'universal_search_page.dart';
import 'settings_page.dart';
import 'budget_page.dart';
import 'import_center_page.dart';
import 'ai_assistant_page.dart';
import 'transactions_page.dart';
import 'data_health_page.dart';
import '../services/data_health_service.dart';
import '../billing/billing_provider.dart';
import '../components/paywall_sheet.dart';

/// DashboardPage — Sagiro Home Screen.
/// Hierarchical structure:
/// 1. Safe Today  •  2. Money Brain  •  3. Quick Actions  •  4. Monthly Status  •
/// 5. What Changed  •  6. Upcoming  •  7. Goals  •  8. Recent Transactions
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _revealedBalances = false;

  String _formatAmount(double amount, NumberFormat currency, bool hideBalances) {
    if (hideBalances && !_revealedBalances) {
      return '₹ ••••••';
    }
    return currency.format(amount);
  }

  String _formatBudget(double budget, NumberFormat currency, bool hideBalances) {
    if (budget <= 0) return 'Not Set';
    if (hideBalances && !_revealedBalances) return '₹ ••••••';
    return currency.format(budget);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    SettingsProvider? settingsProvider;
    try {
      settingsProvider = Provider.of<SettingsProvider>(context);
    } catch (_) {
      settingsProvider = null;
    }
    final hideBalances =
        settingsProvider?.hideBalances ?? AppSettingsService.instance.hideBalances;
    final userName =
        authProvider.userProfile?.displayName.split(' ').first ?? 'Friend';
    final bgColor = AppTheme.backgroundColor(context);
    final cardColor = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.semanticInfo, strokeWidth: 2),
            ),
          );
        }

        final monthlyBudget = provider.monthlyBudget;
        final monthSpent = provider.monthSpend;
        final dailySafeLimit = provider.dailySafeSpendingLimit;
        final transactions = provider.transactions;

        return Scaffold(
          backgroundColor: bgColor,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.electricCyan,
            foregroundColor: Colors.black,
            onPressed: () {
              AppTheme.triggerHaptic(HapticFeedbackType.medium);
              QuickAddModalSheet.show(context);
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          body: RefreshIndicator(
            color: AppTheme.semanticInfo,
            backgroundColor: cardColor,
            onRefresh: () async {
              AppTheme.triggerHaptic(HapticFeedbackType.medium);
              await provider.loadData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -----------------------------------------------------------
                  // HEADER ROW: GREETING & APP BAR ACTIONS
                  // -----------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good day, $userName 👋',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (hideBalances) ...[
                                  InkWell(
                                    onTap: () {
                                      AppTheme.triggerHaptic(HapticFeedbackType.light);
                                      setState(() => _revealedBalances = !_revealedBalances);
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _revealedBalances
                                            ? AppTheme.primaryCyan.withOpacity(0.12)
                                            : AppTheme.cardBorder,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _revealedBalances
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 11,
                                            color: _revealedBalances
                                                ? AppTheme.primaryCyan
                                                : textSecondary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _revealedBalances ? 'Revealed' : 'Masked',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: _revealedBalances
                                                  ? AppTheme.primaryCyan
                                                  : textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          AnimatedScaleButton(
                            onTap: () {
                              AppTheme.triggerHaptic(HapticFeedbackType.selection);
                              final billingProv = Provider.of<BillingProvider>(context, listen: false);
                              if (!billingProv.isPro) {
                                PaywallSheet.showBiometricsAndPrivacy(context);
                                return;
                              }
                              setState(() {
                                _revealedBalances = !_revealedBalances;
                              });
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 1),
                                  content: Text(
                                    _revealedBalances
                                        ? '👁️ Balances Revealed'
                                        : '🔒 Balances Masked (Privacy Protected)',
                                  ),
                                  backgroundColor: AppTheme.surfaceColor(context),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _revealedBalances
                                    ? AppTheme.primaryCyan.withOpacity(0.2)
                                    : cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _revealedBalances
                                      ? AppTheme.primaryCyan
                                      : AppTheme.cardBorder,
                                ),
                              ),
                              child: Icon(
                                _revealedBalances
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: _revealedBalances
                                    ? AppTheme.primaryCyan
                                    : textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedScaleButton(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const UniversalSearchPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Icon(Icons.search_rounded,
                                  color: textPrimary, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedScaleButton(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Icon(Icons.settings_outlined,
                                  color: textPrimary, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // -----------------------------------------------------------
                  // 1. TOTAL FINANCIAL POSITION (NET CASHFLOW & SPEND SNAPSHOT)
                  // -----------------------------------------------------------
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    onTap: hideBalances
                        ? () {
                            AppTheme.triggerHaptic(HapticFeedbackType.light);
                            setState(() =>
                                _revealedBalances = !_revealedBalances);
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL SPENT THIS MONTH',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatAmount(monthSpent, currency, hideBalances),
                                style: AppTheme.monoAmount(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: monthlyBudget > 0 && monthSpent <= monthlyBudget
                                ? AppTheme.secondaryEmerald.withOpacity(0.12)
                                : AppTheme.primaryCyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            monthlyBudget > 0
                                ? 'Budget: ${currency.format(monthlyBudget)}'
                                : '${transactions.length} txns logged',
                            style: TextStyle(
                              color: monthlyBudget > 0 && monthSpent <= monthlyBudget
                                  ? AppTheme.secondaryEmerald
                                  : AppTheme.primaryCyan,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // -----------------------------------------------------------
                  // 2. SAFE TODAY (DOMINANT HERO CARD)
                  // -----------------------------------------------------------
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: monthlyBudget > 0
                        ? AppTheme.primaryCyan.withOpacity(0.35)
                        : AppTheme.semanticWarning.withOpacity(0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: (monthlyBudget > 0
                                            ? AppTheme.primaryCyan
                                            : AppTheme.semanticWarning)
                                        .withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.today_rounded,
                                    color: monthlyBudget > 0
                                        ? AppTheme.primaryCyan
                                        : AppTheme.semanticWarning,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SAFE TODAY',
                                  style: TextStyle(
                                    color: monthlyBudget > 0
                                        ? AppTheme.primaryCyan
                                        : AppTheme.semanticWarning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            if (monthlyBudget > 0)
                              InkWell(
                                onTap: () =>
                                    WhySafeTodaySheet.show(context, provider),
                                child: const Row(
                                  children: [
                                    Text(
                                      'How is this calculated?',
                                      style: TextStyle(
                                        color: AppTheme.primaryCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        color: AppTheme.primaryCyan, size: 9),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (monthlyBudget > 0) ...[
                          InkWell(
                            onTap: hideBalances
                                ? () {
                                    AppTheme.triggerHaptic(HapticFeedbackType.light);
                                    setState(() =>
                                        _revealedBalances = !_revealedBalances);
                                  }
                                : null,
                            child: Text(
                              _formatAmount(dailySafeLimit, currency, hideBalances),
                              style: AppTheme.monoAmount(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dailySafeLimit >= 0
                                ? 'You are within your daily spending limit.'
                                : 'Daily limit exceeded for today.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textPrimary,
                                    side: const BorderSide(
                                        color: AppTheme.darkBorder),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                  icon: const Icon(Icons.tune_rounded,
                                      size: 18),
                                  label: const Text(
                                    'Adjust Budget',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const BudgetPage()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryCyan,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                  icon: const Icon(
                                      Icons.document_scanner_rounded,
                                      size: 16),
                                  label: const Text(
                                    'Scan SMS',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) =>
                                          const SmsScanResultSheet(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'No monthly budget yet',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Set a monthly budget to calculate your daily spending limit.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryCyan,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                            ),
                            icon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 16),
                            label: const Text(
                              'Set Budget',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const BudgetPage()),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // FINANCIAL DATA HEALTH CARD
                  // -----------------------------------------------------------
                  Builder(
                    builder: (context) {
                      final healthReport = DataHealthService.evaluate(provider.transactions);
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.health_and_safety_outlined, color: AppTheme.primaryCyan, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Financial Data Health',
                                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        healthReport.statusBadgeText,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${healthReport.totalTransactions} transactions • ${healthReport.unresolvedDuplicatesCount} duplicates • ${healthReport.transactionsRequiringReviewCount} need review',
                                    style: TextStyle(color: textSecondary, fontSize: 11.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DataHealthPage()),
                                );
                              },
                              child: const Text(
                                'View Details',
                                style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // SECTION 2 — MONTHLY SPENDING PROGRESS
                  // -----------------------------------------------------------
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    onTap: hideBalances
                        ? () {
                            AppTheme.triggerHaptic(HapticFeedbackType.light);
                            setState(() =>
                                _revealedBalances = !_revealedBalances);
                          }
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${DateFormat('MMMM').format(DateTime.now())} Spending',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (monthlyBudget > 0)
                              Text(
                                '${((monthSpent / monthlyBudget) * 100).clamp(0, 999).toStringAsFixed(0)}%',
                                style: AppTheme.monoAmount(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: monthSpent > monthlyBudget
                                      ? AppTheme.semanticDanger
                                      : AppTheme.primaryCyan,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatAmount(monthSpent, currency, hideBalances),
                              style: AppTheme.monoAmount(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              ' / ${_formatBudget(monthlyBudget, currency, hideBalances)}',
                              style: AppTheme.monoAmount(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: monthlyBudget > 0
                                ? (monthSpent / monthlyBudget).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 6,
                            backgroundColor:
                                AppTheme.darkBorder.withOpacity(0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              monthSpent > monthlyBudget
                                  ? AppTheme.semanticDanger
                                  : (monthSpent /
                                              (monthlyBudget > 0
                                                  ? monthlyBudget
                                                  : 1) >
                                          0.85
                                      ? AppTheme.semanticWarning
                                      : AppTheme.secondaryEmerald),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthlyBudget > 0
                                  ? 'Remaining ${currency.format((monthlyBudget - monthSpent).clamp(0.0, double.infinity))}'
                                  : 'Tap to configure monthly budget',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (monthlyBudget > 0)
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const BudgetPage()),
                                  );
                                },
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    color: AppTheme.primaryCyan,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // SECTION 3 — QUICK ACTIONS (ACTION GRID)
                  // -----------------------------------------------------------
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 1. SCAN SMS
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.document_scanner_rounded,
                          label: 'Scan SMS',
                          color: AppTheme.primaryCyan,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const SmsScanResultSheet(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 2. ADD EXPENSE
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Add',
                          color: AppTheme.secondaryEmerald,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const AddTransactionDialog(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 3. IMPORT STATEMENT
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.picture_as_pdf_rounded,
                          label: 'Import',
                          color: AppTheme.primaryCyan,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ImportCenterPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 4. VOICE EXPENSE
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.mic_rounded,
                          label: 'Voice',
                          color: Colors.purpleAccent,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const VoiceExpenseSheet(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // -----------------------------------------------------------
                  // SECTION 4 — MONEY BRAIN INTELLIGENCE
                  // -----------------------------------------------------------
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderColor: AppTheme.primaryCyan.withOpacity(0.25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.psychology_rounded,
                                    color: AppTheme.primaryCyan, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'MONEY BRAIN',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryCyan,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AiAssistantPage()),
                                );
                              },
                              child: const Text(
                                'Ask Money Brain',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          transactions.isNotEmpty
                              ? '"You have logged ${transactions.length} transactions this month."'
                              : '"I need more transaction history before I can give you a useful answer."',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBrainPromptChip(
                                context, 'Where did I spend the most?'),
                            _buildBrainPromptChip(
                                context, 'Can I afford ₹500 today?'),
                            _buildBrainPromptChip(
                                context, 'What changed this month?'),
                            _buildBrainPromptChip(context, 'How much on food?'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // -----------------------------------------------------------
                  // SECTION 5 — RECENT TRANSACTIONS
                  // -----------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT TRANSACTIONS',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (transactions.isNotEmpty)
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TransactionsPage()),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (transactions.isNotEmpty) ...[
                    ...transactions.take(5).map((tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              TransactionDetailSheet.show(context, tx);
                            },
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (tx.type == TransactionType.credit
                                              ? AppTheme.secondaryEmerald
                                              : AppTheme.primaryCyan)
                                          .withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      tx.type == TransactionType.credit
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      color: tx.type == TransactionType.credit
                                          ? AppTheme.secondaryEmerald
                                          : AppTheme.primaryCyan,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.merchant,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${tx.category} • ${DateFormat('MMM d').format(tx.date)}',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${tx.type == TransactionType.credit ? '+' : '-'}${currency.format(tx.amount)}',
                                    style: AppTheme.monoAmount(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: tx.type == TransactionType.credit
                                          ? AppTheme.secondaryEmerald
                                          : textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ] else ...[
                    // EMPTY STATE FOR RECENT TRANSACTIONS
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: textSecondary, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            'No transactions yet.',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your first transaction or scan your bank SMS.',
                            style:
                                TextStyle(color: textSecondary, fontSize: 12.5),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryCyan,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                                icon: const Icon(Icons.document_scanner_rounded,
                                    size: 16),
                                label: const Text(
                                  'Scan Bank SMS',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => const SmsScanResultSheet(),
                                  );
                                },
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: const BorderSide(
                                      color: AppTheme.darkBorder),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text(
                                  'Add Transaction',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        const AddTransactionDialog(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80), // Padding for Floating FAB
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helpers
  Widget _buildBrainPromptChip(BuildContext context, String prompt) {
    final textSecondary = AppTheme.textSecondaryColor(context);

    return AnimatedScaleButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Text(
          prompt,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return AnimatedScaleButton(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        borderColor: color.withOpacity(0.3),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
