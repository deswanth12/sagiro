import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/authentication_provider.dart';
import '../theme/app_theme.dart';
import '../components/sagiro_logo.dart';
import '../components/glass_card.dart';
import '../components/google_signin_button.dart';
import '../components/animated_scale_button.dart';
import 'main_navigation_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        final isLoading = authProvider.status == AuthenticationStatus.loading;

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const SagiroLogo(size: 84, showTagline: false),
                      const SizedBox(height: 28),

                      const Text(
                        'Your Money.\nYour Control.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Privacy-first bank SMS tracker & budget pilot.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 36),

                      // Google Sign-In Action
                      GoogleSigninButton(
                        isLoading: isLoading,
                        onPressed: () async {
                          final success = await authProvider.signInWithGoogle();
                          if (success && context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const MainNavigationScreen()),
                            );
                          } else if (authProvider.errorMessage != null &&
                              context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(authProvider.errorMessage!)),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Continue as Guest Action
                      AnimatedScaleButton(
                        onTap: isLoading
                            ? null
                            : () async {
                                await authProvider.signInAsGuest();
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MainNavigationScreen()),
                                  );
                                }
                              },
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.electricCyan,
                              side: const BorderSide(
                                  color: AppTheme.electricCyan, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    await authProvider.signInAsGuest();
                                    if (context.mounted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const MainNavigationScreen()),
                                      );
                                    }
                                  },
                            child: const Text(
                              'Continue as Guest',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Privacy Guarantee Card
                      const GlassCard(
                        padding: EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shield,
                                    color: AppTheme.electricMint, size: 20),
                                SizedBox(width: 8),
                                Text('100% Privacy Guarantee',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• We never access your bank account\n'
                              '• We never sell your personal financial data\n'
                              '• Your SMS processing stays 100% on your device',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
