import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'add_transaction_dialog.dart';
import 'sms_scan_result_sheet.dart';
import 'voice_expense_sheet.dart';
import '../views/import_center_page.dart';
import '../views/csv_import_page.dart';
import '../models/transaction.dart';

class QuickAddModalSheet extends StatelessWidget {
  const QuickAddModalSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.backgroundColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: const Border(
            top: BorderSide(color: AppTheme.semanticInfo, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Quick Add',
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select entry type to record transaction',
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. EXPENSE
                  _buildOptionTile(
                    context,
                    icon: Icons.remove_circle_outline_rounded,
                    title: 'Expense',
                    subtitle: 'Record an outgoing payment or purchase',
                    color: AppTheme.semanticDanger,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const AddTransactionDialog(
                            initialType: TransactionType.debit),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. INCOME
                  _buildOptionTile(
                    context,
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Income',
                    subtitle: 'Record salary, refund, or incoming cash',
                    color: AppTheme.semanticSuccess,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const AddTransactionDialog(
                            initialType: TransactionType.credit),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 3. SPLIT TRANSACTION
                  _buildOptionTile(
                    context,
                    icon: Icons.call_split_rounded,
                    title: 'Split Transaction',
                    subtitle:
                        'Divide single transaction into multiple categories',
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const AddTransactionDialog(
                          initialType: TransactionType.debit,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 4. SCAN BANK SMS
                  _buildOptionTile(
                    context,
                    icon: Icons.document_scanner_rounded,
                    title: 'Scan Bank SMS',
                    subtitle: 'Auto-import recent bank transactions from SMS',
                    color: AppTheme.electricCyan,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SmsScanResultSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 5. IMPORT STATEMENT
                  _buildOptionTile(
                    context,
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Import Statement',
                    subtitle: 'Import PDF bank statements',
                    color: AppTheme.semanticInfo,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ImportCenterPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 6. IMPORT CSV
                  _buildOptionTile(
                    context,
                    icon: Icons.file_upload_outlined,
                    title: 'Import CSV',
                    subtitle: 'Import spreadsheet or CSV file',
                    color: Colors.tealAccent,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CsvImportPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 7. VOICE
                  _buildOptionTile(
                    context,
                    icon: Icons.mic_rounded,
                    title: 'Voice Expense',
                    subtitle: 'Speak natural entry e.g. "Spent ₹450 at Swiggy"',
                    color: Colors.amberAccent,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const VoiceExpenseSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: color.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
