import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// AnimatedCountUp — Morphing currency counter widget.
/// Smoothly animates numbers upwards or downwards with tabular figure alignment.
class AnimatedCountUp extends StatelessWidget {
  final double value;
  final String prefix;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  const AnimatedCountUp({
    super.key,
    required this.value,
    this.prefix = '₹',
    required this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.fastOutSlowIn,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        symbol: prefix, decimalDigits: 0, locale: 'en_IN');

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedVal, child) {
        final formattedText = currencyFormat.format(animatedVal);
        return Text(
          formattedText,
          style: style.copyWith(
            fontFeatures: [
              const FontFeature.tabularFigures(),
              ...?style.fontFeatures,
            ],
          ),
        );
      },
    );
  }
}
