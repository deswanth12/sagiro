import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../billing/billing_provider.dart';
import '../theme/assistant_theme.dart';
import '../views/premium_page.dart';

class AiProPaywallSheet extends StatelessWidget {
  const AiProPaywallSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiProPaywallSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingProvider = Provider.of<BillingProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AssistantTheme.darkObsidian,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
            top: BorderSide(color: AssistantTheme.electricCyan, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AssistantTheme.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AssistantTheme.electricCyan.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AssistantTheme.electricCyan),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AssistantTheme.electricCyan, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Sagiro AI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sagiro Pro Exclusive',
                        style: TextStyle(
                            color: AssistantTheme.electricCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AssistantTheme.textMuted, size: 22),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text(
              'Get personalized financial insights powered entirely by your own data.',
              style: TextStyle(
                  color: AssistantTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4),
            ),
            const SizedBox(height: 20),

            // Benefits List
            const Text(
              'EXCLUSIVE AI BENEFITS',
              style: TextStyle(
                color: AssistantTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            _buildBenefitItem(
                '⚡ Unlimited Money Guide AI queries (Free tier: 50 tokens limit)'),
            _buildBenefitItem('Analyze your spending habits'),
            _buildBenefitItem('Discover saving opportunities'),
            _buildBenefitItem('Smart budget recommendations'),
            _buildBenefitItem('Subscription analysis & cancellation tips'),
            _buildBenefitItem('Monthly financial summaries'),
            _buildBenefitItem('Merchant spending insights'),
            _buildBenefitItem('Budget forecasting & velocity'),
            _buildBenefitItem('Ask questions about your own finances'),
            _buildBenefitItem(
                'Privacy-first: your financial data never leaves your device'),

            const SizedBox(height: 24),

            // Upgrade Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AssistantTheme.electricCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PremiumPage()));
                },
                child: const Text('Upgrade to Pro',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // Restore Purchases & Maybe Later
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await billingProvider.restorePurchases();
                    },
                    child: const Text('Restore Purchases',
                        style: TextStyle(
                            color: AssistantTheme.electricCyan, fontSize: 13)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Maybe Later',
                        style: TextStyle(
                            color: AssistantTheme.textMuted, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AssistantTheme.electricMint, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AssistantTheme.textPrimary,
                  fontSize: 13.5,
                  height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
