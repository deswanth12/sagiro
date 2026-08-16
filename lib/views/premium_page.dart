import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../billing/billing_provider.dart';
import '../billing/billing_state.dart';
import '../billing/models/subscription_plan.dart';
import '../providers/authentication_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/pricing_card.dart';
import '../components/animated_scale_button.dart';
import 'privacy_policy_page.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  int _selectedPlanIndex = 2; // 2 = Lifetime Pro (₹499 Default Hero)

  Future<bool> _ensureGoogleSignIn(BuildContext context) async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    if (authProvider.isGoogleUser) {
      return true;
    }

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.account_circle_outlined, color: AppTheme.semanticInfo),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Google Account Required',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Google Play Pro subscriptions require a signed-in Google Account to securely bind and restore your subscription across devices.',
          style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.semanticMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.semanticInfo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Sign in with Google',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (shouldLogin == true) {
      final success = await authProvider.signInWithGoogle();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ??
                'Google sign-in required to purchase Pro.'),
            backgroundColor: AppTheme.semanticWarning,
          ),
        );
      }
      return success;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillingProvider>(
      builder: (context, billingProvider, child) {
        final state = billingProvider.state;
        final plans = state.availablePlans.isNotEmpty
            ? state.availablePlans
            : [
                SubscriptionPlan.proMonthly,
                SubscriptionPlan.proYearly,
                SubscriptionPlan.proLifetime,
              ];

        final selectedPlan = _selectedPlanIndex < plans.length
            ? plans[_selectedPlanIndex]
            : plans.last;
        final bgColor = AppTheme.backgroundColor(context);
        final surfaceColor = AppTheme.surfaceColor(context);
        final textPrimary = AppTheme.textPrimaryColor(context);
        final textSecondary = AppTheme.textSecondaryColor(context);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: textPrimary),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text('Sagiro Pro',
                style: TextStyle(
                    color: textPrimary, fontWeight: FontWeight.w900)),
            actions: [
              TextButton.icon(
                onPressed: state.status == BillingStatus.loading
                    ? null
                    : () async {
                        await billingProvider.restorePurchases();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                billingProvider.isPro
                                    ? 'Purchases Restored! Enjoy Sagiro Pro.'
                                    : 'No active Google Play subscription found for this account.',
                              ),
                              backgroundColor: billingProvider.isPro
                                  ? AppTheme.electricMint
                                  : Colors.amber,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.restore,
                    color: AppTheme.electricCyan, size: 18),
                label: const Text('Restore',
                    style: TextStyle(
                        color: AppTheme.electricCyan,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.electricCyan.withOpacity(0.4)),
                        ),
                        child: const Text(
                            '⭐ MOST POPULAR • PAY ONCE, OWN FOREVER',
                            style: TextStyle(
                                color: AppTheme.electricCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Lifetime Pro',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pay Once. Own Forever. Trusted by Privacy-First Users.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Social Proof & Trust Badges
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('🔒 100% Offline',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text('🛡️ Local Privacy',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text('🔑 AES-256 Encrypted',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text('🇮🇳 Made in India',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Flagship Pricing Plan Cards (Lifetime Pro featured top)
                PricingCard(
                  title: 'Lifetime Pro',
                  priceText: '₹699',
                  periodText: 'Pay Once. Own Forever.',
                  badgeText: '⭐ MOST POPULAR • OWN IT FOREVER',
                  isSelected: _selectedPlanIndex == 2,
                  features: SubscriptionPlan.proLifetime.features,
                  onTap: () => setState(() => _selectedPlanIndex = 2),
                ),
                const SizedBox(height: 14),

                PricingCard(
                  title: 'Pro Yearly',
                  priceText: '₹499',
                  periodText: '/ year',
                  badgeText: 'Save 38%',
                  isSelected: _selectedPlanIndex == 1,
                  features: SubscriptionPlan.proYearly.features,
                  onTap: () => setState(() => _selectedPlanIndex = 1),
                ),
                const SizedBox(height: 14),

                PricingCard(
                  title: 'Pro Monthly',
                  priceText: '₹67',
                  periodText: '/ month',
                  isSelected: _selectedPlanIndex == 0,
                  features: SubscriptionPlan.proMonthly.features,
                  onTap: () => setState(() => _selectedPlanIndex = 0),
                ),
                const SizedBox(height: 24),

                // Action Button (Buy Plan)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedScaleButton(
                    onTap: state.status == BillingStatus.purchasing
                        ? () {}
                        : () async {
                            final hasGoogle =
                                await _ensureGoogleSignIn(context);
                            if (hasGoogle && context.mounted) {
                              await billingProvider
                                  .purchasePlan(selectedPlan);
                            }
                          },
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: state.status == BillingStatus.purchasing
                          ? null
                          : () async {
                              final hasGoogle =
                                  await _ensureGoogleSignIn(context);
                              if (hasGoogle && context.mounted) {
                                await billingProvider
                                    .purchasePlan(selectedPlan);
                              }
                            },
                      child: state.status == BillingStatus.purchasing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.black),
                            )
                          : Text(
                              'Get ${selectedPlan.title} (${selectedPlan.priceFormatted})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Private Sync Hero Spotlight Section
                GlassCard(
                  borderColor: AppTheme.electricCyan.withOpacity(0.5),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: AppTheme.electricCyan, size: 24),
                          const SizedBox(width: 10),
                          Text('Private Sync™',
                              style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('Your Cloud. Your Key. Your Data.',
                          style: TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(
                        'Encrypted before upload. Only you can unlock it. Even Google cannot read your backup.',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Feature Comparison Table
                Text('Feature Comparison',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildComparisonRow(
                          context, 'Feature', 'Free', 'Pro',
                          isHeader: true),
                      Divider(color: textSecondary.withOpacity(0.2)),
                      _buildComparisonRow(
                          context, 'Safe Today™ Limit', '✅', '✅'),
                      _buildComparisonRow(
                          context, 'Auto Bank SMS Tracking', '✅', '✅'),
                      _buildComparisonRow(
                          context, 'Financial Calendar', '✅', '✅'),
                      _buildComparisonRow(
                          context, 'Local Device Encrypted Backup', '✅', '✅'),
                      _buildComparisonRow(
                          context, 'Biometric Lock & Security', '❌', '✅'),
                      _buildComparisonRow(
                          context, 'Balance & Amount Masking', '❌', '✅'),
                      _buildComparisonRow(
                          context, 'Private Sync™ Cloud Vault', '❌', '✅'),
                      _buildComparisonRow(
                          context, 'Bank Statement PDF Import', 'Limited', 'Unlimited'),
                      _buildComparisonRow(
                          context, 'Money Brain™ AI Assistant', '❌', '✅'),
                      _buildComparisonRow(
                          context, 'Family Finance Engine', '❌', '✅'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Trust Badges & Links
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user,
                          color: AppTheme.electricCyan, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Google Play Security Verified • Pay Once, Own Forever',
                        style:
                            TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyPage())),
                      child: Text('Privacy Policy',
                          style: TextStyle(
                              color: textSecondary, fontSize: 12)),
                    ),
                    Text('•',
                        style: TextStyle(color: textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyPage())),
                      child: Text('Terms of Service',
                          style: TextStyle(
                              color: textSecondary, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonRow(
      BuildContext context, String feature, String freeVal, String proVal,
      {bool isHeader = false}) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    final style = TextStyle(
      color: isHeader ? AppTheme.electricCyan : textPrimary,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
      fontSize: 13,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: style)),
          Expanded(
              flex: 2,
              child: Text(freeVal,
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                      color: isHeader
                          ? AppTheme.electricCyan
                          : textSecondary,
                      fontWeight: freeVal == '✅' ? FontWeight.bold : FontWeight.normal))),
          Expanded(
              flex: 2,
              child: Text(proVal,
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                      color: isHeader
                          ? AppTheme.electricCyan
                          : AppTheme.electricMint,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
