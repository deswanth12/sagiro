import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/account_detection_engine.dart';
import '../theme/app_theme.dart';
import '../views/account_hub_page.dart';
import 'animated_scale_button.dart';

class AccountsOverviewCard extends StatelessWidget {
  final List<TransactionItem> transactions;

  const AccountsOverviewCard({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final detected = AccountDetectionEngine.detectAccounts(transactions);

    final nowStr = DateFormat('hh:mm a • dd, MMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accounts Header Row with Navigation Arrow
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Accounts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            AnimatedScaleButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountHubPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.electricCyan, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (detected.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.crispBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_rounded,
                    color: AppTheme.textMuted, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Accounts Linked Yet',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Import bank statements or scan SMS to link your accounts.',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Horizontal Carousel of Bank Account Cards
          SizedBox(
            height: 115,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: detected.length,
              itemBuilder: (context, index) {
                final acc = detected[index];
                return _buildBankCard(context, acc, currency, nowStr);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBankCard(BuildContext context, DetectedAccount acc,
      NumberFormat currency, String nowStr) {
    final isSBI =
        acc.bankName.contains('SBI') || acc.bankName.contains('State Bank');
    final isIndiaPost =
        acc.bankName.contains('India Post') || acc.bankName.contains('Post');
    final isHDFC = acc.bankName.contains('HDFC');

    Color cardBgColor = const Color(0xFF162032);
    Color brandAccentColor = AppTheme.electricCyan;

    if (isSBI) {
      cardBgColor = const Color(0xFF132A3E);
      brandAccentColor = const Color(0xFF00A3FF);
    } else if (isIndiaPost) {
      cardBgColor = const Color(0xFF2A1C24);
      brandAccentColor = const Color(0xFFFF5252);
    } else if (isHDFC) {
      cardBgColor = const Color(0xFF152238);
      brandAccentColor = const Color(0xFF2196F3);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountHubPage()),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: brandAccentColor.withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Bank Icon & Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: brandAccentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                _getBankIconText(acc.bankName),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acc.bankName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                'xx${acc.last4Digits}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.sync_rounded,
                            color: Colors.white60, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '🔄 Synced ${acc.bankName} xx${acc.last4Digits} balance.'),
                              backgroundColor: AppTheme.electricCyan,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Bottom Row: Balance & Sync Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nowStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet,
                                  size: 11, color: AppTheme.electricMint),
                              const SizedBox(width: 4),
                              Text(
                                currency.format(acc.balance),
                                style: const TextStyle(
                                  color: AppTheme.electricMint,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${acc.transactionCount} txns',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBankIconText(String bankName) {
    if (bankName.contains('SBI') || bankName.contains('State Bank')) {
      return '🏛️';
    }
    if (bankName.contains('India Post') || bankName.contains('Post')) {
      return '📮';
    }
    if (bankName.contains('HDFC')) return '🏦';
    if (bankName.contains('ICICI')) return '💎';
    if (bankName.contains('Axis')) return '🔺';
    if (bankName.contains('Kotak')) return '🔴';
    return '💳';
  }
}
