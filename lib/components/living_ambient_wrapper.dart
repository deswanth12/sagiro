import 'package:flutter/material.dart';
import '../models/living_ui_state.dart';
import '../theme/app_theme.dart';

/// LivingAmbientWrapper — Ultra-Subtle Ambient Atmosphere Wrapper.
/// Tints the background canvas with an almost imperceptible radial glow (`rgba 0.03` - `0.04`):
/// Users won't consciously notice visual color shifts—they will simply feel calmer.
class LivingAmbientWrapper extends StatelessWidget {
  final LivingState state;
  final Widget child;

  const LivingAmbientWrapper({
    super.key,
    required this.state,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Color auraColor = const Color(0xFF10B981); // Emerald
    if (state == LivingState.caution) {
      auraColor = const Color(0xFFF59E0B); // Amber
    } else if (state == LivingState.alert) {
      auraColor = const Color(0xFFEF4444); // Coral
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.fastOutSlowIn,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.6),
          radius: 1.2,
          colors: [
            auraColor.withOpacity(0.04), // Ultra-subtle 0.04 opacity
            AppTheme.darkBackground,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
