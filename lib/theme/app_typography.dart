import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Sagiro Design System — Typography Tokens (Apple HIG Rule 4)
class AppTypography {
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppTheme.textPrimary,
    height: 1.2,
    letterSpacing: -0.8,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.2,
    letterSpacing: -0.6,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    height: 1.3,
    letterSpacing: -0.4,
  );

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    height: 1.3,
    letterSpacing: -0.1,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppTheme.textPrimary,
    height: 1.4,
    letterSpacing: -0.1,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppTheme.textSecondary,
    height: 1.4,
    letterSpacing: 0.0,
  );

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    color: AppTheme.textMuted,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.4,
  );
}
