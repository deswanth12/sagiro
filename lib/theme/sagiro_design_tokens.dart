import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// SagiroColors — Master Brand Color Palette for Sagiro Personal Finance.
/// Primary: Electric Cyan (#0EA5E9)
/// Secondary: Emerald Mint (#10B981)
/// Obsidian Dark Canvas: (#090C10)
/// Soft Neutral Light Canvas: (#F8FAFC)
class SagiroColors {
  // Brand Accents
  static const Color primaryCyan = Color(0xFF0EA5E9);
  static const Color primaryCyanGlow = Color(0xFF38BDF8);
  static const Color primaryCyanDark = Color(0xFF0284C7);
  static const Color secondaryEmerald = Color(0xFF10B981);
  static const Color secondaryEmeraldLight = Color(0xFF34D399);

  // Status & Semantic Colors
  static const Color semanticSuccess = Color(0xFF10B981);
  static const Color semanticWarning = Color(0xFFF59E0B);
  static const Color semanticDanger = Color(0xFFEF4444);
  static const Color semanticInfo = Color(0xFF3B82F6);
  static const Color purpleGlow = Color(0xFFA855F7);

  // Dark Palette (Sagiro Obsidian)
  static const Color darkBackground = Color(0xFF090C10);
  static const Color darkSurface = Color(0xFF11161F);
  static const Color darkCard = Color(0xFF161C26);
  static const Color darkElevatedCard = Color(0xFF1E2634);
  static const Color darkBorder = Color(0xFF263040);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // AMOLED Palette (Pure Deep Black)
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0A0A0A);
  static const Color amoledCard = Color(0xFF121212);
  static const Color amoledBorder = Color(0xFF202020);

  // Light Palette (Soft Clean Neutral)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevatedCard = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextDisabled = Color(0xFF94A3B8);
}

/// SagiroTypography — Grotesk UI Text & JetBrains Mono Tabular Currency Styles.
class SagiroTypography {
  static TextStyle displayLarge(BuildContext context, {Color? color}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.8,
      color: color ?? AppTheme.textPrimaryColor(context),
    );
  }

  static TextStyle headlineMedium(BuildContext context, {Color? color}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: color ?? AppTheme.textPrimaryColor(context),
    );
  }

  static TextStyle titleMedium(BuildContext context, {Color? color}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color ?? AppTheme.textPrimaryColor(context),
    );
  }

  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? AppTheme.textPrimaryColor(context),
    );
  }

  static TextStyle labelCaps(BuildContext context, {Color? color}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: color ?? AppTheme.textMutedColor(context),
    );
  }

  /// Monospaced Currency & Numeric Figures (JetBrains Mono)
  static TextStyle currencyLarge(BuildContext context, {Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color ?? AppTheme.textPrimaryColor(context),
    );
  }

  static TextStyle currencyMedium(BuildContext context, {Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: color ?? AppTheme.textPrimaryColor(context),
    );
  }

  static TextStyle currencySmall(BuildContext context, {Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color ?? AppTheme.textPrimaryColor(context),
    );
  }
}

/// SagiroSpacing — Standardized 4px baseline grid spacing scale.
class SagiroSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// SagiroRadius — Consistent Border Radius Scale.
class SagiroRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;

  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderPill => BorderRadius.circular(full);
}

/// SagiroElevation — Ambient Shadows & Tonal Depth Tokens.
class SagiroElevation {
  static List<BoxShadow> subtleGlow(Color accentColor, {double opacity = 0.15}) {
    return [
      BoxShadow(
        color: accentColor.withOpacity(opacity),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

/// SagiroAnimations — Transition Durations & Curves with Reduce Motion support.
class SagiroAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.easeOutBack;
}
