import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PulseState {
  calculating, // 🟡 Pulse pulsing during 200ms check
  stable, // 🟢 Solid green glow when safe
  sleep, // 🌙 Calm ambient during night
}

/// FinancialPulseDot — Sagiro's Signature Element.
/// A tiny animated dot that signals real-time system health and 100% on-device calculations.
class FinancialPulseDot extends StatefulWidget {
  final PulseState state;
  final double size;

  const FinancialPulseDot({
    super.key,
    this.state = PulseState.stable,
    this.size = 10.0,
  });

  @override
  State<FinancialPulseDot> createState() => _FinancialPulseDotState();
}

class _FinancialPulseDotState extends State<FinancialPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (widget.state) {
      case PulseState.calculating:
        color = AppTheme.semanticWarning;
        break;
      case PulseState.stable:
        color = AppTheme.semanticSuccess;
        break;
      case PulseState.sleep:
        color = AppTheme.semanticInfo;
        break;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.state == PulseState.calculating
            ? 1.0 + (_controller.value * 0.35)
            : 1.0;
        final alpha = widget.state == PulseState.calculating
            ? 0.5 + (_controller.value * 0.5)
            : 0.9;

        return Container(
          width: widget.size * scale,
          height: widget.size * scale,
          decoration: BoxDecoration(
            color: color.withOpacity(alpha),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 8 * scale,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
