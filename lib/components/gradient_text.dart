import 'package:flutter/material.dart';

/// GradientText — Renders high-legibility text.
/// If gradient is provided, applies a subtle shader mask; otherwise defaults to standard text styling.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    if (gradient == null) {
      return Text(text, style: style);
    }
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient!.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
