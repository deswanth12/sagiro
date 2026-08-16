import 'package:flutter/material.dart';
import 'dart:ui';
import '../components/animated_scale_button.dart';
import '../theme/app_theme.dart';
import '../services/app_settings_service.dart';
import '../services/biometric_auth_service.dart';
import 'dashboard_page.dart';
import 'transactions_page.dart';
import 'ai_assistant_page.dart';
import '../family_engine/pages/family_dashboard_page.dart';
import 'profile_page.dart';

/// MainNavigationScreen — Sagiro 5-Tab Navigation.
/// 🏠 Home  •  💳 Transactions  •  🧠 Money Brain  •  👥 Family  •  🛡 Vault
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLocked = false;
  bool _isAuthenticating = false;

  final List<Widget> _pages = const [
    DashboardPage(), // 🏠 Home
    TransactionsPage(), // 💳 Transactions
    AiAssistantPage(), // 🧠 Money Brain
    FamilyDashboardPage(), // 👥 Family
    ProfilePage(), // 🛡 Vault
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _promptBiometricResume();
    }
  }

  Future<void> _promptBiometricResume() async {
    if (_isAuthenticating) return;
    final biometricsEnabled = AppSettingsService.instance.biometricsEnabled;
    if (!biometricsEnabled) return;

    setState(() => _isLocked = true);
    _isAuthenticating = true;

    try {
      final success = await BiometricAuthService.instance.authenticate(
        reason: 'Unlock Sagiro to continue',
      );
      if (mounted) {
        setState(() {
          _isLocked = !success;
          _isAuthenticating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _isAuthenticating = false;
        });
      }
    }
  }

  void _onTabSelect(int index) {
    AppTheme.triggerHaptic(HapticFeedbackType.selection);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.backgroundColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          if (_isLocked)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: bgColor.withOpacity(0.92),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.electricCyan.withOpacity(0.15),
                            border: Border.all(
                                color: AppTheme.electricCyan, width: 2),
                          ),
                          child: const Icon(Icons.lock_rounded,
                              size: 48, color: AppTheme.electricCyan),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Sagiro is Locked',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Biometric verification required to access your financial data',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Unlock App',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _promptBiometricResume,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildAppleGlassNavBar(context),
    );
  }

  Widget _buildAppleGlassNavBar(BuildContext context) {
    final navBg = AppTheme.surfaceColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: AppTheme.backgroundColor(context),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: navBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: isDark
                    ? AppTheme.crispBorder.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Row(
                children: [
                  _buildNavItem(context, 0, Icons.grid_view_outlined,
                      Icons.grid_view_rounded, 'Home'),
                  _buildNavItem(context, 1, Icons.receipt_long_outlined,
                      Icons.receipt_long_rounded, 'Transactions'),
                  _buildNavItem(context, 2, Icons.psychology_outlined,
                      Icons.psychology_rounded, 'Money Brain'),
                  _buildNavItem(context, 3, Icons.people_outline_rounded,
                      Icons.people_rounded, 'Family'),
                  _buildNavItem(context, 4, Icons.shield_outlined,
                      Icons.shield_rounded, 'Vault'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData outlinedIcon,
      IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final textSecondary = AppTheme.textSecondaryColor(context);
    const activeColor = AppTheme.primaryCyan;

    return Expanded(
      child: AnimatedScaleButton(
        onTap: () => _onTabSelect(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: isSelected ? activeColor : textSecondary,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? activeColor : textSecondary,
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
