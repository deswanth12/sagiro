import 'package:flutter/animation.dart';

/// Sagiro Design System — Motion & Easing Curve Tokens (Apple/Revolut HIG 150ms–250ms)
class AppMotion {
  // Fast, natural spring durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 220);
  static const Duration durationPage = Duration(milliseconds: 250);

  // Premium Apple Easing Curves
  static const Curve curveFastOut = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutQuad;
  static const Curve curvePageTransition = Curves.fastOutSlowIn;
}
