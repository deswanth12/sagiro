import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../services/data_health_service.dart';
import '../services/app_settings_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import 'transaction_review_page.dart';
import 'duplicate_review_page.dart';
import 'import_center_page.dart';

class DataHealthPage extends StatelessWidget {
  const DataHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd • h:mm a');
    final settings = AppSettingsService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Data Health', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          final report = DataHealthService.evaluate(
            provider.transactions,
            lastSmsScan: settings.lastImportTimestamp,
            lastBackup: settings.lastBackupTimestamp,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Status Summary Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.electricCyan.withOpacity(0.15),
                        AppTheme.secondaryEmerald.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.electricCyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCyan.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.health_and_safety_outlined, color: AppTheme.electricCyan, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Data Integrity', style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12)),
                                Text(report.statusBadgeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${report.totalTransactions} transactions evaluated cleanly in local database.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 📊 Metric Breakdown Grid
                Text(
                  'Database Audit Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor(context)),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      label: 'Total Transactions',
                      value: '${report.totalTransactions}',
                      icon: Icons.receipt_long_outlined,
                      color: AppTheme.electricCyan,
                    ),
                    _buildMetricCard(
                      label: 'Income / Credits',
                      value: '${report.incomeCount}',
                      icon: Icons.arrow_downward_rounded,
                      color: AppTheme.semanticSuccess,
                    ),
                    _buildMetricCard(
                      label: 'Expenses / Debits',
                      value: '${report.expenseCount}',
                      icon: Icons.arrow_upward_rounded,
                      color: AppTheme.semanticDanger,
                    ),
                    _buildMetricCard(
                      label: 'Needs Review',
                      value: '${report.transactionsRequiringReviewCount}',
                      icon: Icons.rate_review_outlined,
                      color: report.transactionsRequiringReviewCount > 0 ? AppTheme.warningAmber : AppTheme.semanticSuccess,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🛠️ Action Items Required
                if (report.transactionsRequiringReviewCount > 0 || report.unresolvedDuplicatesCount > 0 || report.failedImportsCount > 0) ...[
                  Text(
                    'Recommended Data Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor(context)),
                  ),
                  const SizedBox(height: 12),
                  if (report.transactionsRequiringReviewCount > 0)
                    _buildActionTile(
                      context: context,
                      icon: Icons.rate_review_outlined,
                      title: '${report.transactionsRequiringReviewCount} transactions need review',
                      subtitle: 'Verify merchant names or amounts',
                      buttonLabel: 'Review Transactions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TransactionReviewPage()),
                        );
                      },
                    ),
                  if (report.unresolvedDuplicatesCount > 0)
                    _buildActionTile(
                      context: context,
                      icon: Icons.copy_rounded,
                      title: '${report.unresolvedDuplicatesCount} duplicate candidates detected',
                      subtitle: 'Clean up duplicate SMS or manual logs',
                      buttonLabel: 'Resolve Duplicates',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DuplicateReviewPage()),
                        );
                      },
                    ),
                  if (report.failedImportsCount > 0)
                    _buildActionTile(
                      context: context,
                      icon: Icons.warning_amber_rounded,
                      title: '${report.failedImportsCount} failed SMS imports logged',
                      subtitle: 'Review error messages or retry parsing',
                      buttonLabel: 'Check Import Center',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ImportCenterPage()),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],

                // 🕒 Timestamps & Audit Info
                Text(
                  'Audit Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor(context)),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildTimestampRow(
                        context: context,
                        label: 'Last SMS Scan Evaluated',
                        value: report.lastSmsScan != null
                            ? dateFormat.format(report.lastSmsScan!)
                            : 'No SMS scanned yet',
                      ),
                      Divider(height: 1, color: AppTheme.borderColor(context)),
                      _buildTimestampRow(
                        context: context,
                        label: 'Last Encrypted Backup',
                        value: report.lastBackup != null
                            ? dateFormat.format(report.lastBackup!)
                            : 'No backup created yet',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.warningAmber, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: onTap,
            child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow({required BuildContext context, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 13)),
          Text(value, style: TextStyle(color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
