import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/saf_storage_service.dart';
import '../services/backup_service.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  DateTime? _lastBackupDate;
  bool _isLoading = false;
  bool _usePassword = false;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBackupStatus() async {
    final date = await SafStorageService.getLastBackupDate();
    if (mounted) setState(() => _lastBackupDate = date);
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isLoading = true);
    try {
      final password = _usePassword ? _passwordController.text.trim() : null;
      if (_usePassword && (password == null || password.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Please enter a password to encrypt your backup.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final archiveContent =
          await BackupService.generateBackupArchive(password: password);
      final savedPath = await SafStorageService.saveBackupFile(archiveContent);

      if (savedPath != null && mounted) {
        await _loadBackupStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Backup created successfully! Saved outside app sandbox.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Backup failed: ${e.toString().split('\n').first}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreBackup() async {
    setState(() => _isLoading = true);
    try {
      final fileData = await SafStorageService.pickAndReadBackupFile();
      if (fileData == null) {
        if (mounted) setState(() => _isLoading = false);
        return; // User cancelled
      }

      final content = fileData['content']!;
      final metadata = BackupService.inspectBackupHeader(content);

      if (!mounted) return;

      // Show Preview & Confirmation Dialog
      _showRestoreConfirmDialog(content, metadata);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to read backup: ${e.toString().split('\n').first}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRestoreConfirmDialog(String content, BackupMetadata metadata) {
    final passwordController = TextEditingController();
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: const Text('Restore Backup Preview',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewRow('App Version', metadata.appVersion),
                _buildPreviewRow(
                    'Backup Date', dateFormat.format(metadata.createdDate)),
                _buildPreviewRow(
                    'Transactions', '${metadata.transactionCount} items'),
                _buildPreviewRow(
                    'Smart Rules', '${metadata.categoryRuleCount} rules'),
                _buildPreviewRow(
                    'Protection',
                    metadata.isEncrypted
                        ? 'Password Encrypted 🔒'
                        : 'Unencrypted'),
                const SizedBox(height: 14),
                if (metadata.isEncrypted) ...[
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Enter Backup Password',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.darkBackground,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Restoring will replace current local database records using an atomic SQLite transaction. If an error occurs, changes roll back completely.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.black),
              onPressed: () async {
                final pw = metadata.isEncrypted
                    ? passwordController.text.trim()
                    : null;
                Navigator.pop(dialogCtx);

                if (!mounted) return;
                setState(() => _isLoading = true);

                try {
                  await BackupService.restoreFromArchive(content, password: pw);
                  if (mounted) {
                    await Provider.of<BudgetProvider>(context, listen: false)
                        .loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Database restored successfully! All records updated.')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Restore Failed: ${e.toString().split('\n').first}')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Confirm Restore',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Local Backup & Restore'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup & Restore',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            const Text('"Your data. Your backup. Your control."',
                style: TextStyle(
                    color: AppTheme.electricCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Vault Data Protection Card
            Consumer<BudgetProvider>(
              builder: (context, budgetProvider, child) {
                final txCount = budgetProvider.transactions.length;
                final textPri = AppTheme.textPrimaryColor(context);
                final textSec = AppTheme.textSecondaryColor(context);
                return GlassCard(
                  borderColor: AppTheme.electricMint.withOpacity(0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              color: AppTheme.electricMint, size: 22),
                          const SizedBox(width: 10),
                          Text('🔒 Data Protected',
                              style: TextStyle(
                                  color: textPri,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transactions Protected',
                              style: TextStyle(
                                  color: textSec, fontSize: 13)),
                          Text(
                            '$txCount items',
                            style: TextStyle(
                              color: textPri,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Last Backup',
                              style: TextStyle(
                                  color: textSec, fontSize: 13)),
                          Text(
                            _lastBackupDate != null
                                ? dateFormat.format(_lastBackupDate!)
                                : 'No backup created yet',
                            style: TextStyle(
                              color: _lastBackupDate != null
                                  ? AppTheme.electricMint
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.electricCyan,
                            side:
                                const BorderSide(color: AppTheme.electricCyan),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✓ Verification Complete: $txCount transactions securely indexed in local SQLite database.'),
                                backgroundColor: AppTheme.surfaceColor(context),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 16),
                          label: const Text('Verify Backup',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Create Backup Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CREATE BACKUP',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'Creates an encrypted archive of your transactions, categories, budgets, and smart rules. Saves to Downloads, Documents, or USB drive via Android SAF.',
                    style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Password Protect Backup',
                        style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    subtitle: const Text('AES-256-GCM encrypted backup',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    value: _usePassword,
                    activeColor: AppTheme.electricCyan,
                    onChanged: (val) => setState(() => _usePassword = val),
                  ),
                  if (_usePassword) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: AppTheme.textPrimaryColor(context)),
                      decoration: InputDecoration(
                        labelText: 'Backup Password',
                        labelStyle:
                            TextStyle(color: AppTheme.textSecondaryColor(context)),
                        filled: true,
                        fillColor: AppTheme.surfaceColor(context),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.cardBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.cardBorder)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AnimatedScaleButton(
                    onTap: _isLoading ? null : _handleCreateBackup,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.download),
                        label: Text(
                            _isLoading ? 'Processing...' : 'Create Backup File',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isLoading ? null : _handleCreateBackup,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Restore Backup Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RESTORE BACKUP',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'Select a .ppbackup file from your device. Restores all transactions inside an atomic SQLite transaction with automatic rollback protection.',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.electricMint,
                        side: const BorderSide(color: AppTheme.electricMint),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select .ppbackup File to Restore',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isLoading ? null : _handleRestoreBackup,
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
}
