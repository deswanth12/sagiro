import 'package:flutter/material.dart';

class AssistantTheme {
  static const Color darkObsidian = Color(0xFF0A0D14);
  static const Color glassSurface = Color(0xFF111622);
  static const Color glassBorder = Color(0xFF222B3E);

  static const Color electricCyan =
      Color(0xFF0EA5E9); // Semantic Info / Interactive
  static const Color electricMint =
      Color(0xFF10B981); // Semantic Success / Money Saved
  static const Color warningAmber = Color(0xFFF59E0B); // Semantic Warning
  static const Color dangerRed = Color(0xFFEF4444); // Semantic Danger

  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color userBubble = Color(0xFF1E2638);
  static const Color assistantBubble = Color(0xFF161E2E);

  static BoxDecoration glassCardDecoration = BoxDecoration(
    color: glassSurface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: glassBorder, width: 1.0),
  );

  static BoxDecoration chipDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected ? electricCyan.withOpacity(0.12) : glassSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isSelected ? electricCyan : glassBorder,
        width: 1.0,
      ),
    );
  }
}
