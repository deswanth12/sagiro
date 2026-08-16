import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CounterAnimation extends StatefulWidget {
  final double targetValue;
  final TextStyle style;
  final String prefix;
  final Duration duration;

  const CounterAnimation({
    super.key,
    required this.targetValue,
    required this.style,
    this.prefix = '₹',
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<CounterAnimation> createState() => _CounterAnimationState();
}

class _CounterAnimationState extends State<CounterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(CounterAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##,##0', 'en_IN');

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = widget.targetValue * _animation.value;
        return Text(
          '${widget.prefix}${currencyFormatter.format(currentValue.round())}',
          style: widget.style,
        );
      },
    );
  }
}
