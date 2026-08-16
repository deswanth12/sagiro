import 'package:flutter/material.dart';
import '../theme/assistant_theme.dart';

class TypingIndicator extends StatefulWidget {
  final String statusText;

  const TypingIndicator({
    super.key,
    this.statusText = 'Analyzing your transactions...',
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AssistantTheme.assistantBubble,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AssistantTheme.glassBorder),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final opacity = ((_controller.value * 3 - index) % 3)
                            .clamp(0.2, 1.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AssistantTheme.electricCyan
                                .withOpacity(opacity),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  widget.statusText,
                  style: const TextStyle(
                    color: AssistantTheme.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
