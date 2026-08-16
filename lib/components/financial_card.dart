import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// FinancialCard — Swiss & Mercury Bank Inspired Container.
/// Micro-animations, smooth touch state feedback, matte surface, 1px border.
class FinancialCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const FinancialCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 16.0,
    this.onTap,
  });

  @override
  State<FinancialCard> createState() => _FinancialCardState();
}

class _FinancialCardState extends State<FinancialCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      transform:
          _isPressed ? (Matrix4.identity()..scale(0.985)) : Matrix4.identity(),
      padding: widget.padding ?? const EdgeInsets.all(20),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppTheme.darkCard,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: _isPressed
              ? (widget.borderColor ?? AppTheme.semanticInfo).withOpacity(0.8)
              : (widget.borderColor ?? AppTheme.cardBorder),
          width: 1.0,
        ),
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
