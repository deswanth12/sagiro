import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../views/premium_page.dart';

class PaywallSheet extends StatelessWidget {
  final String headline;
  final String featureDescription;

  const PaywallSheet({
    super.key,
    required this.headline,
    required this.featureDescription,
  });

  /// Standard Value Trigger
  static void show(BuildContext context,
      {required String title, required String description}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          PaywallSheet(headline: title, featureDescription: description),
    );
  }

  /// High-Converting Value-Moment Triggers
  static void showPrivateSync(BuildContext context) {
    show(
      context,
      title: 'Your Financial History Matters.',
      description:
          'Protect it with encrypted Private Sync™. Your cloud. Your key. Your data.',
    );
  }

  static void showMoneyReplay(BuildContext context) {
    show(
      context,
      title: 'You\'ve Just Relived Your Financial Journey.',
      description:
          'Keep every future replay forever with Lifetime Pro (₹699). Pay once, own forever.',
    );
  }

  static void showFinancialDna(BuildContext context) {
    show(
      context,
      title: 'You\'ve Unlocked Your Financial Personality.',
      description:
          'Get deeper behavioral wealth insights and lifetime AI guidance with Lifetime Pro (₹699).',
    );
  }

  static void showBiometricsAndPrivacy(BuildContext context) {
    show(
      context,
      title: 'Biometric & Balance Privacy Protection',
      description:
          'Protect your financial life with biometric fingerprint authentication and 1-tap balance masking with Sagiro Pro.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.cardColor(context);
    final textPri = AppTheme.textPrimaryColor(context);
    final textSec = AppTheme.textSecondaryColor(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
              top: BorderSide(color: AppTheme.electricCyan, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.electricCyan.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded,
                  color: AppTheme.electricCyan, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textPri,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              featureDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textSec, fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PremiumPage()));
                },
                child: const Text('Get Lifetime Pro — ₹699 (Own Forever)',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Enjoying Free Tier',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
