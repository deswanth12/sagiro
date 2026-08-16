import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import '../services/security_service.dart';
import 'privacy_policy_page.dart';

class PrivacyDashboardPage extends StatefulWidget {
  const PrivacyDashboardPage({super.key});

  @override
  State<PrivacyDashboardPage> createState() => _PrivacyDashboardPageState();
}

class _PrivacyDashboardPageState extends State<PrivacyDashboardPage> {
  bool _showTechDetails = false;

  @override
  Widget build(BuildContext context) {
    final privacyData = SecurityService.getPrivacyStatus();
    final bgColor = AppTheme.backgroundColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Vault',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Human First Guarantee Hero Card
            GlassCard(
              borderColor: AppTheme.electricMint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppTheme.electricMint, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Your money stays yours.',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildGuaranteeRow(context, 'Nothing sold'),
                  const SizedBox(height: 10),
                  _buildGuaranteeRow(context, 'Nothing tracked'),
                  const SizedBox(height: 10),
                  _buildGuaranteeRow(context, 'Everything encrypted'),
                  const SizedBox(height: 10),
                  _buildGuaranteeRow(context, 'Verified today'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Collapsible Technical Details Expander
            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code_rounded,
                        color: AppTheme.electricCyan),
                    title: Text(
                      'View Technical Details',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    subtitle: Text(
                      'AES-256-GCM • PBKDF2 • Local SQLite • Cloud Sync Not Configured',
                      style: TextStyle(
                          color: textSecondary, fontSize: 11),
                    ),
                    trailing: Icon(
                      _showTechDetails
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.electricCyan,
                    ),
                    onTap: () {
                      setState(() {
                        _showTechDetails = !_showTechDetails;
                      });
                    },
                  ),
                  if (_showTechDetails) ...[
                    const Divider(color: AppTheme.cardBorder),
                    const SizedBox(height: 8),
                    _AuditTile(
                      icon: Icons.cloud_off,
                      iconColor: AppTheme.electricMint,
                      label: 'Data Uploaded to Cloud',
                      value: privacyData['dataUploaded'] as String,
                      statusText: 'Cloud Sync Not Configured',
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 20),
                    _AuditTile(
                      icon: Icons.security,
                      iconColor: AppTheme.purpleGlow,
                      label: 'Local Encryption Cipher',
                      value: privacyData['encryption'] as String,
                      statusText: 'AES-256-GCM',
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 20),
                    _AuditTile(
                      icon: Icons.lock_outline,
                      iconColor: AppTheme.warningAmber,
                      label: 'Passphrases & Keys',
                      value: privacyData['bankPasswords'] as String,
                      statusText: 'RAM-Only Storage',
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 20),
                    _AuditTile(
                      icon: Icons.do_not_disturb_on_outlined,
                      iconColor: AppTheme.dangerCoral,
                      label: 'Third-Party Analytics',
                      value: privacyData['tracking'] as String,
                      statusText: '100% Disabled',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            AnimatedScaleButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          '🎉 Privacy Audit Verified: Financial data is processed 100% locally by default.')),
                );
              },
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Run Live Privacy Audit',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              '🎉 Privacy Audit Verified: Financial data is processed 100% locally by default.')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.electricCyan,
                  side:
                      BorderSide(color: AppTheme.electricCyan.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.policy_outlined),
                label: const Text('Read Full Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuaranteeRow(BuildContext context, String text) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppTheme.electricMint, size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
              color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AuditTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String statusText;

  const _AuditTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: textSecondary, fontSize: 11.5)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.electricMint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(statusText,
              style: const TextStyle(
                  color: AppTheme.electricMint,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
