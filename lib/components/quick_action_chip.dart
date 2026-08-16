import 'package:flutter/material.dart';
import '../theme/assistant_theme.dart';

class QuickActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const QuickActionChip({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: AssistantTheme.chipDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AssistantTheme.electricCyan),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: AssistantTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
