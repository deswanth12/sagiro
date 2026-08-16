import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class PricingCard extends StatelessWidget {
  final String title;
  final String priceText;
  final String periodText;
  final String? badgeText;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;

  const PricingCard({
    super.key,
    required this.title,
    required this.priceText,
    required this.periodText,
    this.badgeText,
    required this.features,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected
        ? AppTheme.electricCyan
        : (isDark ? Colors.white10 : Colors.black12);
    final displayPrice =
        priceText.trim().isEmpty ? 'Price unavailable' : priceText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GlassCard(
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(badgeText!,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(displayPrice,
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: displayPrice.length > 8 ? 26 : 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1)),
                  const SizedBox(width: 6),
                  Text(periodText,
                      style: TextStyle(color: textSecondary, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 12),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.electricCyan, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(f,
                              style:
                                  TextStyle(color: textPrimary, fontSize: 13))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
