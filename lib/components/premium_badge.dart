import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumBadge extends StatelessWidget {
  final String label;
  final Color color;

  const PremiumBadge({
    super.key,
    this.label = 'PRO',
    this.color = AppTheme.electricCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
