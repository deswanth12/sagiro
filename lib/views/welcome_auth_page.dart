import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/authentication_provider.dart';
import '../theme/app_theme.dart';
import '../components/sagiro_logo.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import 'main_navigation_screen.dart';

class WelcomeAuthPage extends StatefulWidget {
  const WelcomeAuthPage({super.key});

  @override
  State<WelcomeAuthPage> createState() => _WelcomeAuthPageState();
}

class _WelcomeAuthPageState extends State<WelcomeAuthPage> {
  bool _isLoadingGoogle = false;

  void _enterAsGuest() async {
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);
    await authProvider.signInAsGuest();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      final authProvider =
          Provider.of<AuthenticationProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Signed in as ${authProvider.userProfile?.displayName ?? 'User'}')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else if (authProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: AppTheme.warningAmber,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Guest Mode',
                textColor: Colors.black,
                onPressed: _enterAsGuest,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Login error: ${e.toString()}'),
            backgroundColor: AppTheme.warningAmber,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Guest Mode',
              textColor: Colors.black,
              onPressed: _enterAsGuest,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.backgroundColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const SagiroLogo(size: 80, showTagline: true),
                  const SizedBox(height: 28),

                  Text(
                    'Welcome to Sagiro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'See every expense automatically without typing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.semanticInfo,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 28),

                  // Option 1: Primary Action — Continue as Guest
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.semanticInfo,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _enterAsGuest,
                      child: const Text('Continue as Guest',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppTheme.cardBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR',
                            style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(
                          child: Divider(color: AppTheme.cardBorder)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Option 2: Continue with Google
                  AnimatedScaleButton(
                    onTap: _isLoadingGoogle ? null : _loginWithGoogle,
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isLoadingGoogle ? null : _loginWithGoogle,
                        icon: _isLoadingGoogle
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.semanticInfo),
                              )
                            : Icon(Icons.g_mobiledata,
                                color: textPrimary, size: 28),
                        label: Text('Continue with Google',
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3 Pillar Solutions Badge
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: AppTheme.semanticInfo, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'India\'s Privacy-First Financial Operating System',
                                  style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow('📲 Automatic Bank SMS Tracking',
                            'See every expense automatically without typing'),
                        const SizedBox(height: 6),
                        _buildFeatureRow('🧠 Money Brain AI',
                            'Get instant answers about your own money, 100% privately'),
                        const SizedBox(height: 6),
                        _buildFeatureRow('🎬 Money Replay',
                            'See your entire financial year in 60 seconds'),
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
  }

  Widget _buildFeatureRow(String title, String desc) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle,
            color: AppTheme.semanticSuccess, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text(desc, style: TextStyle(color: textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
