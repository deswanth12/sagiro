import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class PrivacyReceiptSheet extends StatelessWidget {
  final String title;
  final int itemsProcessed;
  final int duplicatesSkipped;

  const PrivacyReceiptSheet({
    super.key,
    required this.title,
    required this.itemsProcessed,
    required this.duplicatesSkipped,
  });

  static void show(
    BuildContext context, {
    required String title,
    required int itemsProcessed,
    required int duplicatesSkipped,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrivacyReceiptSheet(
        title: title,
        itemsProcessed: itemsProcessed,
        duplicatesSkipped: duplicatesSkipped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
            top: BorderSide(color: AppTheme.semanticSuccess, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.semanticSuccess.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: AppTheme.semanticSuccess, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ON-DEVICE PRIVACY RECEIPT',
                        style: TextStyle(
                            color: AppTheme.semanticSuccess,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            borderColor: AppTheme.semanticSuccess.withOpacity(0.2),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildReceiptRow('Local Processing', '100% On-Device'),
                const Divider(color: Colors.white10, height: 20),
                _buildReceiptRow('Cloud Storage', 'Cloud Sync Not Configured'),
                const Divider(color: Colors.white10, height: 20),
                _buildReceiptRow('Items Extracted', '$itemsProcessed items'),
                const Divider(color: Colors.white10, height: 20),
                _buildReceiptRow(
                    'Duplicates Skipped', '$duplicatesSkipped skipped'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.semanticSuccess,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.semanticSuccess,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
