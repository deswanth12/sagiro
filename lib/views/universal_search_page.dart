import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/universal_search_engine.dart';
import '../providers/budget_provider.dart';
import '../account_engine/services/account_detection_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';

class UniversalSearchPage extends StatefulWidget {
  const UniversalSearchPage({super.key});

  @override
  State<UniversalSearchPage> createState() => _UniversalSearchPageState();
}

class _UniversalSearchPageState extends State<UniversalSearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Universal Search Engine',
            style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        centerTitle: true,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final txs = provider.transactions;
          final accounts = AccountDetectionService.processSmsTransactions(
              existingAccounts: [], smsTransactions: txs);
          final goals = provider.savingsGoals;

          final results = UniversalSearchEngine.searchEverything(
            query: _query,
            transactions: txs,
            accounts: accounts,
            goals: goals,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Universal Input
                TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: (val) => setState(() => _query = val),
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search Amazon, HDFC, Food, Rent, Statements...',
                    hintStyle: TextStyle(
                        color: textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.electricCyan, size: 22),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: textSecondary, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: isDark
                            ? BorderSide.none
                            : const BorderSide(color: AppTheme.lightBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: isDark
                            ? BorderSide.none
                            : const BorderSide(color: AppTheme.lightBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppTheme.electricCyan, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),

                if (_query.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                          'Type any keyword to search across Merchants, Accounts, Transactions, Statements, and Insights in 1 step.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  )
                else if (results.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No matching transactions found.',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                else ...[
                  // 1. Merchant Group Results
                  if (results.merchantResults.isNotEmpty) ...[
                    const Text('MERCHANTS FOUND',
                        style: TextStyle(
                            color: AppTheme.electricCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    ...results.merchantResults.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: AppTheme.electricCyan
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.storefront_rounded,
                                      color: AppTheme.electricCyan, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.merchantName,
                                          style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      Text('${m.transactionCount} transactions',
                                          style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(currency.format(m.totalSpend),
                                    style: const TextStyle(
                                        color: AppTheme.dangerCoral,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // 2. Accounts Results
                  if (results.accountResults.isNotEmpty) ...[
                    const Text('ACCOUNTS MATCHED',
                        style: TextStyle(
                            color: AppTheme.semanticSuccess,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    ...results.accountResults.map((acc) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Text(acc.iconEmoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(acc.nickname,
                                          style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      Text(
                                          '${acc.bankName} • ${acc.maskedAccountNumber}',
                                          style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(currency.format(acc.estimatedBalance),
                                    style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ])),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // 3. Transactions Results
                  if (results.transactionResults.isNotEmpty) ...[
                    Text(
                        'TRANSACTIONS MATCHED (${results.transactionResults.length})',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    ...results.transactionResults.take(10).map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.merchant,
                                        style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5)),
                                    Text(
                                        DateFormat('dd MMM, yyyy')
                                            .format(t.date),
                                        style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 11)),
                                  ],
                                ),
                                Text(currency.format(t.amount),
                                    style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ])),
                              ],
                            ),
                          ),
                        )),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
