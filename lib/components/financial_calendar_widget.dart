import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/upcoming_bill.dart';
import '../models/transaction.dart';
import 'glass_card.dart';

class CalendarEventItem {
  final String title;
  final String amountText;
  final Color color;
  final DateTime date;

  const CalendarEventItem({
    required this.title,
    required this.amountText,
    required this.color,
    required this.date,
  });
}

/// FinancialCalendarWidget — Financial Calendar™ Component.
/// Displays real user financial events (recurring expenses, credits/salary).
/// Shows 0 Events & honest empty state for new users with no data.
class FinancialCalendarWidget extends StatelessWidget {
  final double monthlyBudget;
  final double monthSpend;
  final List<UpcomingBill> upcomingBills;
  final List<TransactionItem> transactions;
  final VoidCallback? onAddTransaction;
  final VoidCallback? onAddRecurringExpense;

  const FinancialCalendarWidget({
    super.key,
    required this.monthlyBudget,
    required this.monthSpend,
    this.upcomingBills = const [],
    this.transactions = const [],
    this.onAddTransaction,
    this.onAddRecurringExpense,
  });

  List<CalendarEventItem> _getEvents() {
    final List<CalendarEventItem> events = [];
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // 1. Process active upcoming bills (configured recurring expenses)
    for (final bill in upcomingBills) {
      if (!bill.isActive) continue;

      final titleLower = bill.title.toLowerCase();
      final catLower = bill.category.toLowerCase();

      Color accentColor = AppTheme.semanticInfo;
      if (titleLower.contains('rent') || catLower.contains('rent')) {
        accentColor = AppTheme.semanticInfo;
      } else if (titleLower.contains('emi') ||
          titleLower.contains('loan') ||
          catLower.contains('emi') ||
          catLower.contains('loan')) {
        accentColor = AppTheme.semanticDanger;
      } else if (titleLower.contains('util') ||
          titleLower.contains('power') ||
          titleLower.contains('electric') ||
          titleLower.contains('water') ||
          catLower.contains('util')) {
        accentColor = AppTheme.semanticWarning;
      }

      events.add(CalendarEventItem(
        title: '${bill.providerEmoji} ${bill.title}',
        amountText: currency.format(bill.amount),
        color: accentColor,
        date: bill.dueDate,
      ));
    }

    // 2. Process real credit / salary transactions
    for (final tx in transactions) {
      final isSalary = tx.category.toLowerCase() == 'salary' ||
          tx.merchant.toLowerCase().contains('salary') ||
          (tx.type == TransactionType.credit && tx.amount >= 10000);

      if (isSalary || tx.type == TransactionType.credit) {
        final title = tx.merchant.isNotEmpty ? tx.merchant : 'Salary Credited';
        events.add(CalendarEventItem(
          title: '🟢 $title',
          amountText: currency.format(tx.amount),
          color: AppTheme.semanticSuccess,
          date: tx.date,
        ));
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    final events = _getEvents();

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.semanticInfo.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppTheme.semanticInfo, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Financial Calendar™ • $monthName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${events.length} ${events.length == 1 ? 'Event' : 'Events'}',
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            events.isEmpty
                ? 'No financial events yet'
                : 'See every important financial event before it surprises you.',
            style: TextStyle(
              color: events.isEmpty
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: events.isEmpty ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a transaction or recurring expense to populate your financial calendar.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (onAddTransaction != null)
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.electricCyan,
                                side: const BorderSide(
                                    color: AppTheme.electricCyan, width: 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: onAddTransaction,
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Add transaction',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      if (onAddTransaction != null &&
                          onAddRecurringExpense != null)
                        const SizedBox(width: 8),
                      if (onAddRecurringExpense != null)
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.semanticSuccess,
                                side: const BorderSide(
                                    color: AppTheme.semanticSuccess, width: 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: onAddRecurringExpense,
                              icon: const Icon(Icons.receipt_long, size: 14),
                              label: const Text('Add recurring expense',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: events.map((ev) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildEventBadge(ev.title, ev.amountText, ev.color),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventBadge(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(amount,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
