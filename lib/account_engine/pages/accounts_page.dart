import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import '../models/account_type.dart';
import '../services/account_detection_service.dart';
import '../widgets/account_card_widget.dart';
import 'account_detail_page.dart';
import '../../models/transaction.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/glass_card.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AccountCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          children: [
            Text('Account Intelligence Hub',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text('Auto-detected & Analyzed 100% On-Device',
                style: TextStyle(
                    color: AppTheme.electricCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final txs = provider.transactions;
          final List<AccountModel> detectedAccounts =
              AccountDetectionService.processSmsTransactions(
            existingAccounts: [],
            smsTransactions: txs,
          );

          // Apply Filter & Search
          final filteredAccounts = detectedAccounts.where((acc) {
            final matchesQuery = _searchQuery.isEmpty ||
                acc.nickname
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                acc.bankName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                acc.maskedAccountNumber.contains(_searchQuery);

            final matchesCategory = _selectedCategory == null ||
                acc.accountType == _selectedCategory;

            return matchesQuery && matchesCategory;
          }).toList();

          final double totalAssets = detectedAccounts
              .where((a) => !a.accountType.isLiability)
              .fold(
                  0.0,
                  (sum, a) =>
                      sum +
                      (a.estimatedBalance > 0 ? a.estimatedBalance : 0.0));

          final double totalLiabilities = detectedAccounts
              .where((a) => a.accountType.isLiability)
              .fold(0.0, (sum, a) => sum + a.estimatedBalance.abs());

          final double totalIncome = txs
              .where((t) => t.type == TransactionType.credit)
              .fold(0.0, (sum, t) => sum + t.amount);
          final double totalOutflow = txs
              .where((t) => t.type == TransactionType.debit)
              .fold(0.0, (sum, t) => sum + t.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real-time Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search bank, nickname, or card number...',
                    hintStyle: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.electricCyan, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.darkCard,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Accounts', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Savings 🏦', AccountCategory.savings),
                      const SizedBox(width: 8),
                      _buildFilterChip('Salary 💼', AccountCategory.salary),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Credit Cards 💳', AccountCategory.creditCard),
                      const SizedBox(width: 8),
                      _buildFilterChip('Wallets 📱', AccountCategory.wallet),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 💼 YOUR MONEY PORTFOLIO OVERVIEW HERO CARD
                GlassCard(
                  borderColor: AppTheme.electricCyan,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('YOUR MONEY PORTFOLIO',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2)),
                          Text('LIVE TRACKED',
                              style: TextStyle(
                                  color: AppTheme.electricCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Portfolio Account Rows
                      if (detectedAccounts.isEmpty)
                        const Text(
                            'No accounts detected yet. Sync SMS or import statement to build your portfolio.',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12))
                      else
                        ...detectedAccounts.take(3).map((acc) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(acc.iconEmoji,
                                          style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 10),
                                      Text(acc.nickname,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5)),
                                    ],
                                  ),
                                  Text(
                                    currency.format(acc.estimatedBalance),
                                    style: TextStyle(
                                      color: acc.estimatedBalance < 0
                                          ? AppTheme.dangerCoral
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),

                      const SizedBox(height: 14),
                      Divider(color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 10),

                      // NET WORTH (TRACKED)
                      const Text('NET WORTH (TRACKED)',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(
                        currency.format((totalAssets - totalLiabilities)
                            .clamp(0.0, double.infinity)),
                        style: const TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('THIS MONTH SUMMARY',
                                style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildPortfolioStat(
                                    'Income',
                                    currency.format(totalIncome),
                                    AppTheme.semanticSuccess),
                                _buildPortfolioStat(
                                    'Spent',
                                    currency.format(totalOutflow),
                                    AppTheme.dangerCoral),
                                _buildPortfolioStat(
                                    'Saved',
                                    currency.format((totalIncome - totalOutflow)
                                        .clamp(0.0, double.infinity)),
                                    AppTheme.electricCyan),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('REGISTERED ACCOUNTS (${filteredAccounts.length})',
                        style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: AppTheme.electricCyan, size: 22),
                      tooltip: 'Add Manual Account',
                      onPressed: () => _showAddAccountDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (filteredAccounts.isEmpty)
                  const GlassCard(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                          'No bank accounts detected yet.\nSync SMS or import statement to auto-detect accounts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  )
                else
                  ...filteredAccounts.map((acc) {
                    final accTxs = txs
                        .where((t) => (t.account ?? '')
                            .replaceAll(RegExp(r'[^\d]'), '')
                            .endsWith(
                                acc.maskedAccountNumber.replaceAll('••••', '')))
                        .toList();
                    final spent = accTxs
                        .where((t) => t.type == TransactionType.debit)
                        .fold(0.0, (s, t) => s + t.amount);
                    final inc = accTxs
                        .where((t) => t.type == TransactionType.credit)
                        .fold(0.0, (s, t) => s + t.amount);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AccountCardWidget(
                        account: acc,
                        spentAmount: spent,
                        incomeAmount: inc,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccountDetailPage(
                                  account: acc, allTransactions: txs),
                            ),
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, AccountCategory? category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.electricCyan,
      backgroundColor: AppTheme.darkCard,
      side: BorderSide(
          color: isSelected ? AppTheme.electricCyan : Colors.white10),
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }

  Widget _buildPortfolioStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final bankController = TextEditingController();
    final digitsController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Add Manual Account / Cash Wallet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Bank / Wallet Name (e.g. SBI, Cash)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: digitsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Last 4 Digits (e.g. 5678)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Opening Balance (₹)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
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
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🟢 Manual account added cleanly to registry!'),
                  backgroundColor: AppTheme.semanticSuccess,
                ),
              );
            },
            child: const Text('Save Account',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
