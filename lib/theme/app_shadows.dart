import 'package:flutter/material.dart';

/// Sagiro Design System — Ambient Glass Shadow & Elevation Tokens (Apple HIG)
class AppShadows {
  /// Subtle elevation shadow for primary cards
  static final BoxShadow cardAmbient = BoxShadow(
    color: Colors.black.withOpacity(0.25),
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );

  /// Floating hero card elevation shadow
  static final BoxShadow heroElevation = BoxShadow(
    color: Colors.black.withOpacity(0.35),
    blurRadius: 32,
    spreadRadius: -4,
    offset: const Offset(0, 12),
  );

  /// Subtle glow for active interactive components
  static final BoxShadow cyanGlow = BoxShadow(
    color: const Color(0xFF0EA5E9).withOpacity(0.20),
    blurRadius: 16,
    spreadRadius: -2,
    offset: const Offset(0, 4),
  );

  static final List<BoxShadow> subtleCard = [cardAmbient];
  static final List<BoxShadow> floatingHero = [heroElevation];
  static final List<BoxShadow> interactiveCyan = [cyanGlow];
}
