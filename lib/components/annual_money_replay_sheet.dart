import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'money_replay_share_card.dart';

class AnnualMoneyReplaySheet extends StatefulWidget {
  const AnnualMoneyReplaySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AnnualMoneyReplaySheet(),
    );
  }

  @override
  State<AnnualMoneyReplaySheet> createState() => _AnnualMoneyReplaySheetState();
}

class _AnnualMoneyReplaySheetState extends State<AnnualMoneyReplaySheet> {
  int _currentChapter = 0;
  final int _totalChapters = 7;

  void _nextChapter() {
    if (_currentChapter < _totalChapters - 1) {
      setState(() => _currentChapter++);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousChapter() {
    if (_currentChapter > 0) {
      setState(() => _currentChapter--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final currentYear = DateTime.now().year;

        final yearTxs = provider.transactions
            .where((tx) => tx.date.year == currentYear)
            .toList();

        final double totalIncome = yearTxs
            .where((tx) => tx.type == TransactionType.credit)
            .fold(0.0, (sum, tx) => sum + tx.amount);

        final double totalSpent = yearTxs
            .where((tx) => tx.type == TransactionType.debit)
            .fold(0.0, (sum, tx) => sum + tx.amount);

        final double totalSaved =
            (totalIncome - totalSpent).clamp(0.0, double.infinity);
        final double savingsRate =
            totalIncome > 0 ? (totalSaved / totalIncome) * 100 : 0;

        // Dynamic Theme Color Determination
        Color themeAccent = AppTheme.electricCyan;
        if (savingsRate >= 30) {
          themeAccent = AppTheme.semanticSuccess; // 🟢 Mint Green Theme
        } else if (totalSpent > totalIncome && totalIncome > 0) {
          themeAccent = AppTheme.warningAmber; // 🟠 Amber Theme
        } else if (totalSaved > 100000) {
          themeAccent = const Color(globalGold); // ✨ Gold Glow Theme
        }

        // Financial DNA Personality Classifier
        String personalityTitle = 'The Planner';
        String personalityDesc =
            'You stayed consistently within budget and maintained disciplined savings.';
        if (savingsRate >= 35) {
          personalityTitle = 'The Master Saver';
          personalityDesc =
              'You converted a substantial portion of income straight into long-term wealth.';
        } else if (yearTxs.any((tx) =>
            tx.category.toLowerCase().contains('travel') ||
            tx.category.toLowerCase().contains('food'))) {
          personalityTitle = 'The Life Explorer';
          personalityDesc =
              'Travel and memorable experiences were your biggest investments this year.';
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Story Progress Indicator Bars
              Row(
                children: List.generate(_totalChapters, (index) {
                  final isActive = index == _currentChapter;
                  final isPassed = index < _currentChapter;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? themeAccent
                            : (isActive ? themeAccent : Colors.white12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: themeAccent, size: 20),
                      const SizedBox(width: 8),
                      Text('Your $currentYear Money Replay',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chapter Story Canvas
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    final dx = details.localPosition.dx;
                    final width = MediaQuery.of(context).size.width;
                    if (dx < width * 0.3) {
                      _previousChapter();
                    } else {
                      _nextChapter();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: themeAccent.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: themeAccent.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildChapterContent(
                        currentYear,
                        totalIncome,
                        totalSpent,
                        totalSaved,
                        themeAccent,
                        personalityTitle,
                        personalityDesc,
                        currency),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tap Instructions Footer
              const Text('Tap right to continue • Tap left to go back',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  static const int globalGold = 0xFFFFD700;

  Widget _buildChapterContent(
      int year,
      double income,
      double spent,
      double saved,
      Color accent,
      String dnaTitle,
      String dnaDesc,
      NumberFormat currency) {
    switch (_currentChapter) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_rounded, color: accent, size: 56),
            const SizedBox(height: 16),
            Text('Your $year Financial Story',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
                'A cinematic 60-second journey through your real seasons, milestones, and financial DNA.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(20)),
              child: const Text('▶ Tap Anywhere to Begin',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ],
        );

      case 1:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱 SPRING • MARCH TO MAY',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Icon(Icons.eco_rounded, color: accent, size: 48),
            const SizedBox(height: 12),
            const Text('Spring Savings Momentum',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(income > 0 ? currency.format(income) : 'No income recorded',
                style: TextStyle(
                    color: accent, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text('Your financial engine established its annual baseline.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        );

      case 2:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('☀️ SUMMER • JUNE TO AUGUST',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            SizedBox(height: 16),
            Icon(Icons.wb_sunny_rounded,
                color: AppTheme.warningAmber, size: 48),
            SizedBox(height: 12),
            Text('Summer Life Milestones',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Peak Spending Season',
                style: TextStyle(
                    color: AppTheme.warningAmber,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 12),
            Text(
                'Your highest spending months — filled with real life experiences.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        );

      case 3:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🍂 AUTUMN • SEPTEMBER TO NOVEMBER',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            SizedBox(height: 16),
            Icon(Icons.stars_rounded, color: AppTheme.purpleGlow, size: 48),
            SizedBox(height: 12),
            Text('Autumn Discipline Win',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Savings Milestone Reached',
                style: TextStyle(
                    color: AppTheme.purpleGlow,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 12),
            Text('Maintained disciplined spending during festival season.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        );

      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧬 FINANCIAL DNA PERSONALITY',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Icon(Icons.fingerprint_rounded, color: accent, size: 48),
            const SizedBox(height: 12),
            Text(dnaTitle,
                style: TextStyle(
                    color: accent, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(dnaDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
          ],
        );

      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('❄️ WINTER • YEAR END CULMINATION',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 14),
            Text('You Saved ${currency.format(saved)}',
                style: TextStyle(
                    color: accent, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final provider = Provider.of<BudgetProvider>(context);
                final txs = provider.transactions;
                final budget = provider.monthlyBudget;
                final now = DateTime.now();
                final oldest = txs.isEmpty
                    ? now
                    : txs
                        .map((t) => t.date)
                        .reduce((a, b) => a.isBefore(b) ? a : b);
                final historyDays = now.difference(oldest).inDays + 1;

                final hasEnoughData = historyDays >= 30 && budget > 0;
                final String scoreText;
                if (!hasEnoughData) {
                  scoreText = 'Not enough data for financial health score';
                } else {
                  final withinBudget = provider.monthSpend <= budget;
                  scoreText = withinBudget ? '100%' : '50%';
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Budget Success Rate',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12)),
                            Text(scoreText,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))
                          ]),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
                '"You saved ${currency.format(saved)} this year — every rupee counts towards your financial freedom."',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: accent, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        );

      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome,
                color: AppTheme.electricCyan, size: 48),
            const SizedBox(height: 14),
            const Text('Your Story Continues...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('The next chapter of your financial life begins today.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.electricCyan,
                  side: const BorderSide(color: AppTheme.electricCyan),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Money Replay Card',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  MoneyReplayShareCard.show(
                    context,
                    year: year,
                    totalSaved: saved,
                    savingsStreakDays: 0,
                    financialPersonality: dnaTitle,
                    topMilestone: 'Year in Review',
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text('▶ Begin ${year + 1}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
