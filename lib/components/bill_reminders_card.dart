import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/upcoming_bill.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class BillRemindersCard extends StatelessWidget {
  final List<UpcomingBill> bills;
  final VoidCallback onAddBill;
  final Function(UpcomingBill)? onEditBill;
  final Function(UpcomingBill)? onTogglePause;
  final Function(String)? onDeleteBill;

  const BillRemindersCard({
    super.key,
    required this.bills,
    required this.onAddBill,
    this.onEditBill,
    this.onTogglePause,
    this.onDeleteBill,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    // Find if any active bill is due soon (within 3 days)
    final dueSoonBills = bills.where((b) => b.isDueSoon).toList();

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.repeat_rounded,
                      color: AppTheme.secondaryEmerald, size: 18),
                  SizedBox(width: 8),
                  Text('FIXED EXPENSES',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1)),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onAddBill,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryEmerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.secondaryEmerald.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add,
                          color: AppTheme.secondaryEmerald, size: 14),
                      SizedBox(width: 4),
                      Text('Add Fixed Expense',
                          style: TextStyle(
                              color: AppTheme.secondaryEmerald,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 🔔 UX Improvement: Coming Soon Alert Banner
          if (dueSoonBills.isNotEmpty) ...[
            ...dueSoonBills.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.semanticWarning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.semanticWarning.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: AppTheme.semanticWarning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '🔔 ${b.title} due in ${b.daysRemaining == 0 ? 'today' : '${b.daysRemaining} days'}',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          currency.format(b.amount),
                          style: const TextStyle(
                              color: AppTheme.semanticWarning,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )),
          ],

          // ── Real Data or Clean Empty State ──────────────────────────
          if (bills.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppTheme.textMuted, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No fixed expenses added yet',
                      style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add Rent, Mobile, Internet, or College Fees so Safe Today can reserve money for them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryEmerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onPressed: onAddBill,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Fixed Expense',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...bills.map((bill) {
              final isUrgent = bill.isDueSoon;
              final badgeColor = !bill.isActive
                  ? AppTheme.textMuted
                  : (isUrgent
                      ? AppTheme.semanticWarning
                      : AppTheme.secondaryEmerald);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: bill.isActive
                            ? badgeColor.withOpacity(0.2)
                            : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(bill.providerEmoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(bill.title,
                                    style: TextStyle(
                                        color: bill.isActive
                                            ? AppTheme.textPrimary
                                            : AppTheme.textMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                if (!bill.isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Paused',
                                        style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currency.format(bill.amount)} ${bill.frequencyLabel} • ${bill.dueLabel}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            color: AppTheme.textMuted, size: 20),
                        color: AppTheme.darkCard,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (action) {
                          if (action == 'edit' && onEditBill != null) {
                            onEditBill!(bill);
                          } else if (action == 'toggle' &&
                              onTogglePause != null) {
                            onTogglePause!(bill);
                          } else if (action == 'delete' &&
                              onDeleteBill != null) {
                            onDeleteBill!(bill.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    size: 18, color: AppTheme.textPrimary),
                                const SizedBox(width: 10),
                                Text('Edit Expense',
                                    style: AppTheme.bodyPrimary()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                    bill.isActive
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_outline,
                                    size: 18,
                                    color: AppTheme.textPrimary),
                                const SizedBox(width: 10),
                                Text(
                                    bill.isActive
                                        ? 'Pause Expense'
                                        : 'Resume Expense',
                                    style: AppTheme.bodyPrimary()),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: AppTheme.semanticDanger),
                                SizedBox(width: 10),
                                Text('Delete',
                                    style: TextStyle(
                                        color: AppTheme.semanticDanger)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
