import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              context,
              'Sagiro Privacy Policy',
              'Last updated: August 2026\nEffective date: August 2026',
              isTitle: true,
            ),
            _section(
              context,
              '1. Introduction',
              'Sagiro ("we", "our", "the app") is a 100% on-device, privacy-first personal finance application. We are committed to protecting your financial data. This policy explains how Sagiro handles your information.',
            ),
            _section(
              context,
              '2. Data We Collect',
              'Sagiro is designed with a local-first architecture. Your financial data is stored and processed on your device by default.\n\n'
                  '• SMS Messages: Sagiro requests READ_SMS permission solely to read bank transaction messages from your local SMS inbox. These messages are processed entirely on your device using on-device parsing. No SMS content is transmitted to external servers.\n\n'
                  '• Transaction Data: All transaction records you add (manually, via SMS, or CSV) are stored locally in a SQLite database on your device by default.\n\n'
                  '• No Mandatory Account: Sagiro works in full local mode. If you choose to enable optional Private Sync, end-to-end encrypted backups are stored in your personal Google Drive account.',
            ),
            _section(
              context,
              '3. Data We Do NOT Collect',
              '• We do not collect your name, email, or phone number\n'
                  '• We do not collect your bank account credentials or passwords\n'
                  '• We do not upload any SMS content to any server\n'
                  '• We do not run any analytics or crash tracking by default\n'
                  '• We do not use advertising SDKs\n'
                  '• We do not sell data to third parties\n'
                  '• Your financial data is processed 100% locally on your device by default. If optional Private Sync is enabled, end-to-end encrypted backups are stored in your personal Google Drive account.',
            ),
            _section(
              context,
              '4. SMS Permission Justification',
              'Sagiro requests READ_SMS permission exclusively to auto-detect bank debit/credit transactions from Indian bank senders (HDFC, SBI, ICICI, Axis, Kotak, PayTM, PhonePe, etc.).\n\n'
                  'This is the core functionality of the app: automatic local expense tracking from bank SMS messages, with 100% on-device processing.\n\n'
                  'If you deny SMS permission, Sagiro continues to function fully via Manual Entry and CSV Import.',
            ),
            _section(
              context,
              '5. Data Storage & Security',
              'All data is stored in a local SQLite database on your device. We recommend enabling device-level encryption (available on all modern Android devices) to protect your data at rest.',
            ),
            _section(
              context,
              '6. Data Sharing',
              'We do not share any data with any third parties. There are no analytics SDKs, advertising SDKs, or crash reporting tools embedded in this app.',
            ),
            _section(
              context,
              '7. Children\'s Privacy',
              'Sagiro is not directed at children under 13. We do not knowingly collect data from children.',
            ),
            _section(
              context,
              '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. Updates will be reflected in the app. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),
            _section(
              context,
              '9. Contact Us',
              'If you have questions about this Privacy Policy, contact us at:\nsagirocustomerservice@gmail.com',
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.electricCyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.electricCyan.withOpacity(0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: AppTheme.electricCyan, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your bank SMS stays on your phone.\nYour money stays private. Always.',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4),
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

  Widget _section(BuildContext context, String heading, String body, {bool isTitle = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              color: isTitle ? AppTheme.electricCyan : AppTheme.textPrimaryColor(context),
              fontSize: isTitle ? 20 : 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
                color: AppTheme.textSecondaryColor(context), fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
