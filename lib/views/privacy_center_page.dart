import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_settings_service.dart';
import '../services/database_helper.dart';
import '../services/backup_service.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';

class PrivacyCenterPage extends StatefulWidget {
  const PrivacyCenterPage({super.key});

  @override
  State<PrivacyCenterPage> createState() => _PrivacyCenterPageState();
}

class _PrivacyCenterPageState extends State<PrivacyCenterPage> {
  bool _smsGranted = false;
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final sms = await Permission.sms.status;
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final notification = await Permission.notification.status;

    if (mounted) {
      setState(() {
        _smsGranted = sms.isGranted;
        _cameraGranted = camera.isGranted;
        _micGranted = mic.isGranted;
        _notificationGranted = notification.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
    final textPrimary = AppTheme.textPrimaryColor(context);
    final bgColor = AppTheme.backgroundColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy & Security',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛡️ Top Trust Guarantee Card
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
                    child: const Icon(Icons.shield_outlined, color: AppTheme.electricCyan, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% On-Device Privacy',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your financial records are stored locally with AES-256 encryption. Zero telemetry & zero cloud uploads.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🔑 Permissions & Feature Access
            Text(
              'App Permissions & Access',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 12),
            _buildPermissionCard(
              context: context,
              icon: Icons.sms_outlined,
              title: 'SMS Access',
              purpose: 'Used to automatically detect bank spending and credit transactions.',
              isGranted: _smsGranted,
              onManage: () async {
                await openAppSettings();
                _checkPermissions();
              },
            ),
            const SizedBox(height: 12),
            _buildPermissionCard(
              context: context,
              icon: Icons.camera_alt_outlined,
              title: 'Camera Access',
              purpose: 'Used for scanning paper receipts and bank statements via OCR.',
              isGranted: _cameraGranted,
              onManage: () async {
                await openAppSettings();
                _checkPermissions();
              },
            ),
            const SizedBox(height: 12),
            _buildPermissionCard(
              context: context,
              icon: Icons.mic_none_outlined,
              title: 'Microphone Access',
              purpose: 'Used for hands-free voice expense logging.',
              isGranted: _micGranted,
              onManage: () async {
                await openAppSettings();
                _checkPermissions();
              },
            ),
            const SizedBox(height: 12),
            _buildPermissionCard(
              context: context,
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              purpose: 'Used for daily safe budget reminders and bill due alerts.',
              isGranted: _notificationGranted,
              onManage: () async {
                await openAppSettings();
                _checkPermissions();
              },
            ),
            const SizedBox(height: 24),

            // 💾 Security & AI Processing Status
            Text(
              'Security & Processing Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              context: context,
              icon: Icons.cloud_done_outlined,
              title: 'Cloud Backup',
              statusText: 'Private Sync Available',
              description: 'Backups are stored end-to-end encrypted in your personal storage.',
              isPositive: true,
            ),
            const SizedBox(height: 12),
            _buildStatusCard(
              context: context,
              icon: Icons.psychology_outlined,
              title: 'AI / Money Brain Processing',
              statusText: '100% On-Device Local',
              description: 'Queries are processed strictly on your phone. No financial data sent to remote AI services.',
              isPositive: true,
            ),
            const SizedBox(height: 24),

            // 🕒 Last Data Activity Audit Log
            Text(
              'Data Activity Audit Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _buildAuditRow(
                    context: context,
                    label: 'Last SMS Scan',
                    value: settings.lastImportTimestamp != null
                        ? dateFormat.format(settings.lastImportTimestamp!)
                        : 'Never scanned yet',
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 1),
                  _buildAuditRow(
                    context: context,
                    label: 'Last Encrypted Backup',
                    value: settings.lastBackupTimestamp != null
                        ? dateFormat.format(settings.lastBackupTimestamp!)
                        : 'No backup created yet',
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 1),
                  _buildAuditRow(
                    context: context,
                    label: 'AI Local Engine',
                    value: 'Active (Offline Ready)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 🎛️ Data Control & Ownership
            Text(
              'Data Control & Ownership',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download_outlined, color: AppTheme.electricCyan),
                    title: Text('Export My Data', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Export all transactions and settings to encrypted JSON payload.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: () => _exportData(context),
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.dangerCoral),
                    title: const Text('Delete All Financial Data', style: TextStyle(color: AppTheme.dangerCoral, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Permanently wipe all financial records from Sagiro database.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    onTap: () => _confirmDeleteAllData(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String purpose,
    required bool isGranted,
    required VoidCallback onManage,
  }) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isGranted ? AppTheme.semanticSuccess : AppTheme.warningAmber, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isGranted ? AppTheme.semanticSuccess : AppTheme.warningAmber).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isGranted ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            color: isGranted ? AppTheme.semanticSuccess : AppTheme.warningAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(purpose, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.3)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        side: BorderSide(color: AppTheme.electricCyan.withOpacity(0.5)),
                      ),
                      onPressed: onManage,
                      child: Text(
                        isGranted ? 'Manage' : 'Enable',
                        style: const TextStyle(color: AppTheme.electricCyan, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String statusText,
    required String description,
    required bool isPositive,
  }) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.electricCyan, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(statusText, style: const TextStyle(color: AppTheme.semanticSuccess, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditRow({required BuildContext context, required String label, required String value}) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Text(value, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final jsonString = await BackupService.generateBackupArchive();

    if (context.mounted) {
      final cardBg = AppTheme.cardColor(context);
      final textPrimary = AppTheme.textPrimaryColor(context);
      final textSecondary = AppTheme.textSecondaryColor(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardBg,
          title: Text('Export Data Ready', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          content: Text('Successfully generated backup payload containing ${provider.transactions.length} transactions.\n\nFile length: ${jsonString.length} bytes.',
              style: TextStyle(color: textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: AppTheme.electricCyan)),
            ),
          ],
        ),
      );
    }
  }

  void _confirmDeleteAllData(BuildContext context) {
    final confirmController = TextEditingController();
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Delete All Financial Data?', style: TextStyle(color: AppTheme.dangerCoral, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permanently removes your Sagiro financial records from this device.\n\nType DELETE to confirm:',
              style: TextStyle(color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              autofocus: true,
              style: TextStyle(color: textPrimary),
              decoration: const InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerCoral, foregroundColor: Colors.white),
            onPressed: () async {
              if (confirmController.text.trim() == 'DELETE') {
                Navigator.pop(ctx);
                await DatabaseHelper.instance.clearAllData();
                if (context.mounted) {
                  Provider.of<BudgetProvider>(context, listen: false).loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All financial records permanently deleted.')),
                  );
                }
              }
            },
            child: const Text('Delete All Data', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
