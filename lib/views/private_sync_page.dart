import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/budget_provider.dart';
import '../security/encryption_engine.dart';
import '../security/secure_key_storage.dart';
import '../services/private_sync_service.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import 'restore_flow_page.dart';
import '../billing/feature_access.dart';
import '../components/paywall_sheet.dart';

/// PrivateSyncPage — Private Sync™ Mission Control Screen.
class PrivateSyncPage extends StatefulWidget {
  const PrivateSyncPage({super.key});

  @override
  State<PrivateSyncPage> createState() => _PrivateSyncPageState();
}

class _PrivateSyncPageState extends State<PrivateSyncPage> {
  DateTime? _lastBackupTime;
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    final health = PrivateSyncService.evaluateBackupHealth(_lastBackupTime);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vault',
                style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4)),
            Text('Your financial data stays protected.',
                style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 11.5)),
          ],
        ),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Backup Health Score Card
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  borderColor: AppTheme.semanticSuccess.withOpacity(0.4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: AppTheme.semanticSuccess
                                        .withOpacity(0.12),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.shield_rounded,
                                    color: AppTheme.semanticSuccess, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(health.statusLabel,
                                      style: TextStyle(
                                          color: AppTheme.textPrimaryColor(context),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                          'Local Vault (Cloud Sync Not Configured)',
                                          style: TextStyle(
                                              color: AppTheme.textSecondaryColor(context),
                                              fontSize: 11)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.semanticSuccess
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('Synced 🟢',
                                            style: TextStyle(
                                                color: AppTheme.semanticSuccess,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text('${health.healthScore}%',
                              style: const TextStyle(
                                  color: AppTheme.semanticSuccess,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: health.healthScore / 100.0,
                          backgroundColor:
                              AppTheme.semanticSuccess.withOpacity(0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.semanticSuccess),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Last Encrypted Backup',
                              style: TextStyle(
                                  color: AppTheme.textMutedColor(context),
                                  fontSize: 11)),
                          Text(health.lastBackupRelative,
                              style: TextStyle(
                                  color: AppTheme.textPrimaryColor(context),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Action Trigger Buttons
                Row(
                  children: [
                    Expanded(
                      child: AnimatedScaleButton(
                        onTap: () => _triggerBackup(provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryDeepEmerald,
                                AppTheme.secondaryEmerald
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.semanticSuccess.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isBackingUp
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_clock_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('Back Up Now',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedScaleButton(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RestoreFlowPage())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor(context)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.download_rounded,
                                  color: AppTheme.semanticSuccess, size: 18),
                              const SizedBox(width: 6),
                              Text('Restore Flow',
                                  style: TextStyle(
                                      color: AppTheme.textPrimaryColor(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. 24-Character Recovery Key Sheet Trigger
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  borderColor: AppTheme.semanticWarning.withOpacity(0.3),
                  onTap: () => _showRecoveryKeySheet(context),
                  child: Row(
                    children: [
                      const Icon(Icons.key_rounded,
                          color: AppTheme.semanticWarning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('24-Character Recovery Key',
                                style: TextStyle(
                                    color: AppTheme.textPrimaryColor(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('High-entropy key for phone recovery',
                                style: TextStyle(
                                    color: AppTheme.textSecondaryColor(context),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textMutedColor(context), size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Security Audit Log
                Text('SECURITY AUDIT LOG',
                    style: TextStyle(
                        color: AppTheme.textMutedColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                GlassCard(
                  borderRadius: 20,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: PrivateSyncService.securityLogs
                        .map((log) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded,
                                      color: AppTheme.semanticSuccess,
                                      size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(log.title,
                                        style: TextStyle(
                                            color: AppTheme.textPrimaryColor(context),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Text('Today',
                                      style: TextStyle(
                                          color: AppTheme.textMutedColor(context),
                                          fontSize: 11)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _triggerBackup(BudgetProvider provider) async {
    if (!FeatureAccess.canAccess(PremiumFeature.privateSync)) {
      PaywallSheet.showPrivateSync(context);
      return;
    }

    setState(() => _isBackingUp = true);
    AppTheme.triggerHaptic(HapticFeedbackType.medium);

    try {
      // Load the user's persisted recovery key (or create one if first-time).
      final passphrase = await SecureKeyStorage.getRecoveryKey() ??
          EncryptionEngine.generate24CharRecoveryKey();
      await SecureKeyStorage.saveRecoveryKey(passphrase);

      final bytes = await PrivateSyncService.createStructuredBackupArchive(
        transactions: provider.transactions,
        goalsCount: provider.savingsGoals.length,
        passphrase: passphrase,
      );

      if (!GoogleDriveSyncService.isConfigured) {
        setState(() => _isBackingUp = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Local Vault Only: Google Drive Sync is not configured. Export encrypted backup manually.'),
              backgroundColor: AppTheme.semanticInfo,
            ),
          );
        }
        return;
      }

      await GoogleDriveSyncService.uploadEncryptedBackup(
        archiveBytes: bytes,
        fileName: 'backup.ppbackup',
      );

      setState(() {
        _lastBackupTime = DateTime.now();
        _isBackingUp = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '🟢 Private Sync Protected! Everything securely encrypted.'),
            backgroundColor: AppTheme.semanticSuccess,
          ),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Backup error: $e'),
              backgroundColor: AppTheme.semanticDanger),
        );
      }
    }
  }

  void _showRecoveryKeySheet(BuildContext context) async {
    final key = await SecureKeyStorage.getRecoveryKey() ??
        EncryptionEngine.generate24CharRecoveryKey();
    await SecureKeyStorage.saveRecoveryKey(key);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('24-Character Recovery Key',
                style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
                'Save this key securely. You will need it to unlock your data on a new device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 12)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.semanticWarning.withOpacity(0.4))),
              child: Text(key,
                  style: const TextStyle(
                      color: AppTheme.semanticWarning,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedScaleButton(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: key));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Recovery Key copied to clipboard!')));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: AppTheme.semanticInfo,
                      borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: const Text('Copy Key & Confirm',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
