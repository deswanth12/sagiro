import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme — SAGIRO Premium Indian Fintech Theme Architecture.
/// Brand Vision: "Financial clarity in under 3 seconds."
class AppTheme {
  // ── SAGIRO OFFICIAL COLOR SYSTEM (Luminous Intelligence / Obsidian) ──────
  static const Color primaryCyan = Color(0xFF0EA5E9); // Electric Cyan
  static const Color secondaryCyan = Color(0xFF38BDF8); // Cyan Glow
  static const Color primaryDeepEmerald = Color(0xFF0B3D2E);
  static const Color secondaryEmerald = Color(0xFF10B981); // Emerald Mint
  static const Color accentLime = Color(0xFF10B981);

  // Light Mode Palette (Dedicated Premium Light Design)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevatedCard = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextDisabled = Color(0xFF94A3B8);

  // Dark Mode Palette (Obsidian Precision System)
  static const Color darkBackground = Color(0xFF090C10);
  static const Color darkSurface = Color(0xFF12161F);
  static const Color darkCard = Color(0xFF12161F);
  static const Color darkElevatedCard = Color(0xFF1A202C);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkTextDisabled = Color(0xFF475569);

  // Semantics
  static const Color semanticSuccess =
      Color(0xFF10B981); // Income & Positive (Emerald)
  static const Color semanticIncome = Color(0xFF10B981); // Credit & Income
  static const Color semanticWarning =
      Color(0xFFF59E0B); // Budget Pacing Alert (Amber)
  static const Color semanticDanger =
      Color(0xFFEF4444); // Expense & Danger (Soft Coral)
  static const Color semanticInfo =
      Color(0xFF0EA5E9); // Information & Actions (Cyan)
  static const Color semanticMuted = Color(0xFF64748B); // Neutral Muted Labels

  // Backward-Compatible Color Tokens for UI Components
  static const Color brandCyan = primaryCyan;
  static const Color brandViolet = primaryCyan;
  static const Color electricCyan = primaryCyan;
  static const Color electricMint = secondaryEmerald;
  static const Color neonMint = secondaryEmerald;
  static const Color purpleGlow = primaryCyan;
  static const Color successGreen = semanticSuccess;
  static const Color emeraldGreen = semanticSuccess;
  static const Color warningAmber = semanticWarning;
  static const Color amberWarning = semanticWarning;
  static const Color dangerCoral = semanticDanger;
  static const Color coralRed = semanticDanger;
  static const Color cyanPulse = primaryCyan;

  static const Color cardBorder = darkBorder;
  static const Color crispBorder = darkBorder;

  // Text Color Tokens (Default Dark)
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = semanticMuted;

  // Standard Spacing Tokens (4-8-12-16-20-24-32 Scale)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Standard Typography Tokens
  static TextStyle displayHeader({Color color = textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: -0.5).copyWith(decoration: TextDecoration.none);
  static TextStyle sectionHeader({Color color = textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.3).copyWith(decoration: TextDecoration.none);
  static TextStyle cardHeader({Color color = textPrimary}) => GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.2).copyWith(decoration: TextDecoration.none);
  static TextStyle bodyPrimary({Color color = textPrimary}) =>
      GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: color,
          height: 1.4).copyWith(decoration: TextDecoration.none);
  static TextStyle bodySecondary({Color color = textSecondary}) =>
      GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: color,
          height: 1.4).copyWith(decoration: TextDecoration.none);
  static TextStyle captionText({Color color = semanticMuted}) =>
      GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.normal, color: color).copyWith(decoration: TextDecoration.none);
  static TextStyle buttonText({Color color = Colors.black}) =>
      GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.bold, color: color).copyWith(decoration: TextDecoration.none);

  /// Tabular Monospaced Currency & Number Typography (JetBrains Mono)
  static TextStyle monoAmount({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      ).copyWith(decoration: TextDecoration.none);

  // SAGIRO Motion Tokens
  static const Duration motionInstant = Duration(milliseconds: 120);
  static const Duration motionNormal = Duration(milliseconds: 220);
  static const Duration motionEmotional = Duration(milliseconds: 500);

  // SAGIRO Premium Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryDeepEmerald, secondaryEmerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondaryEmerald, accentLime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [semanticSuccess, Color(0xFF237A4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [secondaryEmerald, Color(0xFF065F44)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [darkTextPrimary, darkTextSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Haptic Feedback Engine
  static void triggerHaptic(
      [HapticFeedbackType type = HapticFeedbackType.light]) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// SAGIRO Light Theme Architecture
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryCyan,
        onPrimary: Colors.white,
        secondary: secondaryEmerald,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        outline: lightBorder,
        outlineVariant: lightElevatedCard,
        error: semanticDanger,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: lightTextSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        modalBackgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        hintStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
        prefixIconColor: primaryCyan,
        suffixIconColor: lightTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder),
        ),
        textStyle: GoogleFonts.inter(color: lightTextPrimary, fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          letterSpacing: -0.4,
        ),
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: lightTextPrimary,
            letterSpacing: -1.5),
        headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: lightTextPrimary,
            letterSpacing: -0.6),
        titleLarge: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
            letterSpacing: -0.4),
        bodyLarge: GoogleFonts.inter(
            fontSize: 15,
            color: lightTextPrimary,
            height: 1.4,
            letterSpacing: -0.2),
        bodyMedium: GoogleFonts.inter(
            fontSize: 13,
            color: lightTextSecondary,
            height: 1.4,
            letterSpacing: -0.1),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryDeepEmerald,
        unselectedItemColor: semanticMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }

  /// SAGIRO Dark Theme Architecture
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentLime,
        onPrimary: Colors.black,
        secondary: secondaryEmerald,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        outline: darkBorder,
        outlineVariant: darkElevatedCard,
        error: semanticDanger,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: crispBorder, width: 1),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: darkTextSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        modalBackgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        hintStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        prefixIconColor: primaryCyan,
        suffixIconColor: darkTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
        textStyle: GoogleFonts.inter(color: darkTextPrimary, fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.4,
        ),
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: darkTextPrimary,
            letterSpacing: -1.5),
        headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: darkTextPrimary,
            letterSpacing: -0.6),
        titleLarge: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
            letterSpacing: -0.4),
        bodyLarge: GoogleFonts.inter(
            fontSize: 15,
            color: darkTextPrimary,
            height: 1.4,
            letterSpacing: -0.2),
        bodyMedium: GoogleFonts.inter(
            fontSize: 13,
            color: darkTextSecondary,
            height: 1.4,
            letterSpacing: -0.1),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: accentLime,
        unselectedItemColor: semanticMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }

  // AMOLED Mode Palette (Pure Black System)
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0E0E0E);
  static const Color amoledCard = Color(0xFF141619);
  static const Color amoledElevatedCard = Color(0xFF1A1D20);
  static const Color amoledBorder = Color(0xFF202020);

  /// Context-aware Theme Token Resolvers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static bool isAmoled(BuildContext context) =>
      isDark(context) &&
      Theme.of(context).scaffoldBackgroundColor == amoledBackground;

  static Color backgroundColor(BuildContext context) {
    if (isLight(context)) return lightBackground;
    return isAmoled(context) ? amoledBackground : darkBackground;
  }

  static Color surfaceColor(BuildContext context) {
    if (isLight(context)) return lightSurface;
    return isAmoled(context) ? amoledSurface : darkSurface;
  }

  static Color cardColor(BuildContext context) {
    if (isLight(context)) return lightCard;
    return isAmoled(context) ? amoledCard : darkCard;
  }

  static Color elevatedCardColor(BuildContext context) {
    if (isLight(context)) return lightElevatedCard;
    return isAmoled(context) ? amoledElevatedCard : darkElevatedCard;
  }

  static Color borderColor(BuildContext context) {
    if (isLight(context)) return lightBorder;
    return isAmoled(context) ? amoledBorder : darkBorder;
  }

  static Color textPrimaryColor(BuildContext context) {
    return isLight(context) ? lightTextPrimary : darkTextPrimary;
  }

  static Color textSecondaryColor(BuildContext context) {
    return isLight(context) ? lightTextSecondary : darkTextSecondary;
  }

  static Color textMutedColor(BuildContext context) {
    return isLight(context) ? lightTextMuted : darkTextMuted;
  }

  static Color textDisabledColor(BuildContext context) {
    return isLight(context) ? lightTextDisabled : darkTextDisabled;
  }

  /// SAGIRO AMOLED Theme Architecture
  static ThemeData get amoledTheme {
    return darkTheme.copyWith(
      scaffoldBackgroundColor: amoledBackground,
      colorScheme: darkTheme.colorScheme.copyWith(
        surface: amoledSurface,
        outline: amoledBorder,
        outlineVariant: amoledElevatedCard,
      ),
      cardTheme: CardTheme(
        color: amoledCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: amoledBorder, width: 1),
        ),
      ),
      dialogTheme: darkTheme.dialogTheme.copyWith(
        backgroundColor: amoledCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: amoledBorder, width: 1),
        ),
      ),
      bottomSheetTheme: darkTheme.bottomSheetTheme.copyWith(
        backgroundColor: amoledCard,
        modalBackgroundColor: amoledCard,
      ),
      inputDecorationTheme: darkTheme.inputDecorationTheme.copyWith(
        fillColor: amoledCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: amoledBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: amoledBorder),
        ),
      ),
    );
  }
}

enum HapticFeedbackType { light, medium, selection }
