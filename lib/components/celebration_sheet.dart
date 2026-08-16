import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'animated_scale_button.dart';

/// CelebrationSheet — Emotional Moment Engine Sheet.
/// Celebrates financial milestones (First Salary, Goal Complete, ₹1 Lakh Saved)
/// with joyful haptics and calm, proud copywriting.
class CelebrationSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amountText;
  final String emoji;

  const CelebrationSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountText,
    this.emoji = '🎉',
  });

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String amountText,
    String emoji = '🎉',
  }) {
    AppTheme.triggerHaptic(HapticFeedbackType.medium);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CelebrationSheet(
        title: title,
        subtitle: subtitle,
        amountText: amountText,
        emoji: emoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.semanticSuccess.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(emoji, style: const TextStyle(fontSize: 54)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GlassCard(
            borderRadius: 20,
            borderColor: AppTheme.semanticSuccess.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Text(
              amountText,
              style: const TextStyle(
                color: AppTheme.semanticSuccess,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AnimatedScaleButton(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.semanticSuccess,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Celebrate & Continue',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
