import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreateAccountSheet extends StatelessWidget {
  final String triggerFeature;

  const CreateAccountSheet({super.key, required this.triggerFeature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.electricMint.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'UNLOCK $triggerFeature',
                  style: const TextStyle(
                      color: AppTheme.electricMint,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Create Free Account',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep your local data intact while unlocking cloud security and multi-device access.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),

          // 4 Benefits Pillars
          const _BenefitTile(
            icon: Icons.cloud_done_outlined,
            iconColor: AppTheme.cyanPulse,
            title: '☁️ Cloud Backup',
            subtitle:
                'End-to-end encrypted backup of your transactions & smart rules.',
          ),
          const SizedBox(height: 12),
          const _BenefitTile(
            icon: Icons.devices_outlined,
            iconColor: AppTheme.electricMint,
            title: '📱 Multi-Device',
            subtitle:
                'Seamlessly access your financial insights on Phone, Tablet & Web.',
          ),
          const SizedBox(height: 12),
          const _BenefitTile(
            icon: Icons.people_outline,
            iconColor: AppTheme.purpleGlow,
            title: '👨‍👩‍👧 Family Sharing',
            subtitle:
                'Share budget goals and split monthly expenses with family.',
          ),
          const SizedBox(height: 12),
          const _BenefitTile(
            icon: Icons.restore_outlined,
            iconColor: AppTheme.warningAmber,
            title: '🔄 Restore Data',
            subtitle: 'Instant 1-click restore when switching to a new phone.',
          ),
          const SizedBox(height: 24),

          // Primary Sign Up CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricMint,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Continue with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Account created! Local data linked securely to cloud backup.')),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue in Guest Mode (Offline)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
