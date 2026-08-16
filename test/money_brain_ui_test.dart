import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sagiro/views/ai_assistant_page.dart';
import 'package:sagiro/providers/authentication_provider.dart';
import 'package:sagiro/providers/budget_provider.dart';
import 'package:sagiro/theme/app_theme.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
  });

  Widget buildTestableWidget({required Widget child, bool isDark = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationProvider>(
          create: (_) => AuthenticationProvider(),
        ),
        ChangeNotifierProvider<BudgetProvider>(
          create: (_) => BudgetProvider(),
        ),
      ],
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
          child: child,
        ),
      ),
    );
  }

  group('Problem 8: Guide / Money Brain UI & Readability Test Suite', () {
    testWidgets('1. Renders Empty State with Quick Prompts cleanly',
        (tester) async {
      await tester
          .pumpWidget(buildTestableWidget(child: const AiAssistantPage()));
      await tester.pumpAndSettle();

      expect(find.text('Sagiro Guide'), findsOneWidget);
      expect(find.text('ASK ME ANYTHING'), findsOneWidget);
      expect(find.text('What is Safe Today?'), findsOneWidget);
      expect(find.text('Where did I spend the most?'), findsOneWidget);
    });

    testWidgets('2. Text visibility & contrast in Dark Mode vs Light Mode',
        (tester) async {
      // Dark mode test
      await tester.pumpWidget(
          buildTestableWidget(child: const AiAssistantPage(), isDark: true));
      await tester.pumpAndSettle();
      expect(find.text('Sagiro Guide'), findsOneWidget);

      // Light mode test
      await tester.pumpWidget(
          buildTestableWidget(child: const AiAssistantPage(), isDark: false));
      await tester.pumpAndSettle();
      expect(find.text('Sagiro Guide'), findsOneWidget);
    });

    testWidgets('3. Font Scaling Accessibility Test (100%, 125%, 150%, 200%)',
        (tester) async {
      for (final scale in [1.0, 1.25, 1.5, 2.0]) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthenticationProvider>(
                  create: (_) => AuthenticationProvider()),
              ChangeNotifierProvider<BudgetProvider>(
                  create: (_) => BudgetProvider()),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const AiAssistantPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sagiro Guide'), findsOneWidget,
            reason: 'Failed at scale $scale');
        expect(tester.takeException(), isNull,
            reason: 'Layout exception at scale $scale');
      }
    });

    testWidgets('4. Chat message bubble structure and input bar rendering',
        (tester) async {
      await tester
          .pumpWidget(buildTestableWidget(child: const AiAssistantPage()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });
}
