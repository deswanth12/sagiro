import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'animated_scale_button.dart';

/// GlassCard — Ultra-Sleek Frosted Glass Container.
/// Crafted for Apple/Linear style cards with crisp borders and ambient backdrop blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 22.0,
    this.onTap,
    this.blurAmount = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppTheme.cardColor(context);
    final effectiveBorder = borderColor ?? AppTheme.borderColor(context);

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return AnimatedScaleButton(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
