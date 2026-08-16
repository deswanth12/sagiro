import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/authentication_provider.dart';
import '../theme/app_theme.dart';
import '../components/sagiro_logo.dart';
import '../services/app_settings_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/database_helper.dart';
import 'onboarding_page.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();

    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    await AppSettingsService.instance.loadSettings();

    await Future.delayed(const Duration(milliseconds: 2200));

    if (mounted && AppSettingsService.instance.biometricsEnabled) {
      bool authenticated = false;
      while (!authenticated && mounted) {
        authenticated = await BiometricAuthService.instance.authenticate(
          reason: 'Unlock Sagiro to access your account',
        );
        if (!authenticated && mounted) {
          final retry = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardColor(ctx),
              title: Text('App Locked',
                  style: TextStyle(color: AppTheme.textPrimaryColor(ctx))),
              content: Text(
                'Biometric or screen lock authentication is required to access Sagiro.',
                style: TextStyle(color: AppTheme.textSecondaryColor(ctx)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Retry Unlock',
                      style: TextStyle(color: AppTheme.electricCyan)),
                ),
              ],
            ),
          );
          if (retry != true) break;
        }
      }
    }

    if (!mounted) return;

    final hasExistingData = authProvider.isLoggedIn ||
        AppSettingsService.instance.hasCompletedOnboarding ||
        (await DatabaseHelper.instance.getAllTransactions()).isNotEmpty;

    if (!mounted) return;

    final targetWidget = hasExistingData
        ? const MainNavigationScreen()
        : const OnboardingPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => targetWidget,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: const SagiroLogo(
              size: 90,
              showTagline: true,
            ),
          ),
        ),
      ),
    );
  }
}
