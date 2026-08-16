import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/feature_access.dart';
import '../theme/app_theme.dart';

class RestorePurchaseDialog {
  static Future<void> show(BuildContext context) async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return const AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: Text('Restoring Purchases',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.electricCyan),
              SizedBox(height: 16),
              Text('Connecting to Google Play Store...',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        );
      },
    );

    await provider.restorePurchases();

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog

      final isProNow = provider.isPro;
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppTheme.darkCard,
            title: Text(
              isProNow ? 'Purchases Restored!' : 'No Active Subscription Found',
              style: TextStyle(
                  color:
                      isProNow ? AppTheme.electricMint : AppTheme.dangerCoral,
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              isProNow
                  ? 'Your ${provider.currentTier.displayName} status is active on this device.'
                  : 'We could not find an active Google Play subscription linked to your Google Play account.',
              style:
                  const TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }
}
