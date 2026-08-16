import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sagiro/theme/app_theme.dart';
import 'package:sagiro/theme/sagiro_design_tokens.dart';

/// Helper to calculate relative luminance according to WCAG 2.1
double _calculateLuminance(Color color) {
  double transform(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    } else {
      return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  final r = transform(color.red / 255.0);
  final g = transform(color.green / 255.0);
  final b = transform(color.blue / 255.0);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Helper to calculate contrast ratio between two colors according to WCAG 2.1
double _calculateContrastRatio(Color foreground, Color background) {
  final l1 = _calculateLuminance(foreground);
  final l2 = _calculateLuminance(background);
  final brighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (brighter + 0.05) / (darker + 0.05);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Theme Architecture & Design Tokens Regression Suite', () {
    testWidgets('Light Theme Tokens: Background, Surface, Card & Text Colors', (tester) async {
      final lightTheme = AppTheme.lightTheme;

      // 1. Scaffold background must not match primary text
      expect(lightTheme.scaffoldBackgroundColor, isNot(equals(AppTheme.lightTextPrimary)));
      expect(lightTheme.scaffoldBackgroundColor, equals(AppTheme.lightBackground));

      // 2. Card surface must not match primary text
      expect(lightTheme.cardTheme.color, isNot(equals(AppTheme.lightTextPrimary)));
      expect(lightTheme.cardTheme.color, equals(AppTheme.lightCard));

      // 3. Dialog surface must not match dialog text
      expect(lightTheme.dialogTheme.backgroundColor, isNot(equals(AppTheme.lightTextPrimary)));
      expect(lightTheme.dialogTheme.backgroundColor, equals(AppTheme.lightCard));

      // 4. Input fill color must not match input text color
      expect(lightTheme.inputDecorationTheme.fillColor, isNot(equals(AppTheme.lightTextPrimary)));

      // 5. Text primary must be dark in light mode
      expect(AppTheme.lightTextPrimary, equals(const Color(0xFF0F172A)));
      expect(AppTheme.lightTextSecondary, equals(const Color(0xFF475569)));
      expect(AppTheme.lightTextMuted, equals(const Color(0xFF64748B)));
      expect(AppTheme.lightTextDisabled, equals(const Color(0xFF94A3B8)));

      // 6. Text hierarchy must be preserved (not all pure black)
      expect(AppTheme.lightTextPrimary, isNot(equals(Colors.black)));
      expect(AppTheme.lightTextSecondary, isNot(equals(AppTheme.lightTextPrimary)));
      expect(AppTheme.lightTextMuted, isNot(equals(AppTheme.lightTextSecondary)));
      expect(AppTheme.lightTextDisabled, isNot(equals(AppTheme.lightTextMuted)));
    });

    testWidgets('Light Theme WCAG Contrast Ratios', (tester) async {
      // Primary text on white card (Target >= 7.0:1 for AAA)
      final primaryOnWhiteRatio = _calculateContrastRatio(AppTheme.lightTextPrimary, AppTheme.lightCard);
      expect(primaryOnWhiteRatio, greaterThanOrEqualTo(12.0),
          reason: 'Primary text on white card must meet WCAG AAA');

      // Primary text on light background (Target >= 7.0:1 for AAA)
      final primaryOnBgRatio = _calculateContrastRatio(AppTheme.lightTextPrimary, AppTheme.lightBackground);
      expect(primaryOnBgRatio, greaterThanOrEqualTo(12.0),
          reason: 'Primary text on light background must meet WCAG AAA');

      // Secondary text on white card (Target >= 4.5:1 for AA)
      final secondaryOnWhiteRatio = _calculateContrastRatio(AppTheme.lightTextSecondary, AppTheme.lightCard);
      expect(secondaryOnWhiteRatio, greaterThanOrEqualTo(5.0),
          reason: 'Secondary text on white card must meet WCAG AA');

      // Muted text on white card (Target >= 3.0:1 for UI elements/captions)
      final mutedOnWhiteRatio = _calculateContrastRatio(AppTheme.lightTextMuted, AppTheme.lightCard);
      expect(mutedOnWhiteRatio, greaterThanOrEqualTo(3.5),
          reason: 'Muted text on white card must have sufficient readability');
    });

    testWidgets('Dark Theme: Background, Surface, Card & Text Colors', (tester) async {
      final darkTheme = AppTheme.darkTheme;

      // 1. Scaffold background must not match primary text
      expect(darkTheme.scaffoldBackgroundColor, isNot(equals(AppTheme.textPrimary)));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppTheme.darkBackground));

      // 2. Card surface must not match primary text
      expect(darkTheme.cardTheme.color, isNot(equals(AppTheme.textPrimary)));
      expect(darkTheme.cardTheme.color, equals(AppTheme.darkCard));

      // 3. Dialog surface must not match dialog text
      expect(darkTheme.dialogTheme.backgroundColor, isNot(equals(AppTheme.textPrimary)));

      // 4. Contrast ratio check for dark mode
      final primaryOnDarkBg = _calculateContrastRatio(AppTheme.textPrimary, AppTheme.darkBackground);
      expect(primaryOnDarkBg, greaterThanOrEqualTo(10.0));
    });

    testWidgets('AMOLED Theme: Pure Black Background & Contrast', (tester) async {
      final amoledTheme = AppTheme.amoledTheme;

      // 1. Scaffold background must be pure black
      expect(amoledTheme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));

      // 2. Scaffold background must not match primary text
      expect(amoledTheme.scaffoldBackgroundColor, isNot(equals(AppTheme.textPrimary)));

      // 3. Card color in AMOLED
      expect(amoledTheme.cardTheme.color, equals(AppTheme.amoledCard));

      // 4. Contrast ratio against pure black
      final amoledRatio = _calculateContrastRatio(AppTheme.textPrimary, const Color(0xFF000000));
      expect(amoledRatio, greaterThanOrEqualTo(15.0));
    });

    testWidgets('AppTheme Context-Aware Resolvers in Light Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              expect(AppTheme.isLight(context), isTrue);
              expect(AppTheme.isDark(context), isFalse);
              expect(AppTheme.isAmoled(context), isFalse);

              expect(AppTheme.textPrimaryColor(context), equals(AppTheme.lightTextPrimary));
              expect(AppTheme.textSecondaryColor(context), equals(AppTheme.lightTextSecondary));
              expect(AppTheme.textMutedColor(context), equals(AppTheme.lightTextMuted));
              expect(AppTheme.textDisabledColor(context), equals(AppTheme.lightTextDisabled));

              expect(AppTheme.backgroundColor(context), equals(AppTheme.lightBackground));
              expect(AppTheme.surfaceColor(context), equals(AppTheme.lightSurface));
              expect(AppTheme.cardColor(context), equals(AppTheme.lightCard));
              expect(AppTheme.borderColor(context), equals(AppTheme.lightBorder));

              // Test dynamic typography in light mode
              final headline = SagiroTypography.headlineMedium(context);
              expect(headline.color, equals(AppTheme.lightTextPrimary));

              final caps = SagiroTypography.labelCaps(context);
              expect(caps.color, equals(AppTheme.lightTextMuted));

              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('AppTheme Context-Aware Resolvers in Dark Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              expect(AppTheme.isLight(context), isFalse);
              expect(AppTheme.isDark(context), isTrue);

              expect(AppTheme.textPrimaryColor(context), equals(AppTheme.textPrimary));
              expect(AppTheme.textSecondaryColor(context), equals(AppTheme.textSecondary));
              expect(AppTheme.textMutedColor(context), equals(AppTheme.textMuted));

              expect(AppTheme.backgroundColor(context), equals(AppTheme.darkBackground));
              expect(AppTheme.surfaceColor(context), equals(AppTheme.darkSurface));
              expect(AppTheme.cardColor(context), equals(AppTheme.darkCard));

              // Test dynamic typography in dark mode
              final headline = SagiroTypography.headlineMedium(context);
              expect(headline.color, equals(AppTheme.textPrimary));

              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('AppTheme Context-Aware Resolvers in AMOLED Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.amoledTheme,
          home: Builder(
            builder: (context) {
              expect(AppTheme.isLight(context), isFalse);
              expect(AppTheme.isDark(context), isTrue);
              expect(AppTheme.isAmoled(context), isTrue);

              expect(AppTheme.backgroundColor(context), equals(const Color(0xFF000000)));
              expect(AppTheme.cardColor(context), equals(AppTheme.amoledCard));

              return Container();
            },
          ),
        ),
      );
    });

    test('SagiroColors Dynamic Color Tokens', () {
      expect(SagiroColors.lightTextPrimary, equals(const Color(0xFF0F172A)));
      expect(SagiroColors.lightTextSecondary, equals(const Color(0xFF475569)));
      expect(SagiroColors.lightTextMuted, equals(const Color(0xFF64748B)));
      expect(SagiroColors.lightTextDisabled, equals(const Color(0xFF94A3B8)));
      expect(SagiroColors.lightBackground, equals(const Color(0xFFF8FAFC)));
      expect(SagiroColors.lightCard, equals(const Color(0xFFFFFFFF)));
    });
  });
}
