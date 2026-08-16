import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/authentication_provider.dart';
import '../views/login_page.dart';
import '../theme/app_theme.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.status == AuthenticationStatus.loading) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.electricCyan),
            ),
          );
        }

        if (authProvider.isLoggedIn) {
          return child;
        }

        return const LoginPage();
      },
    );
  }
}
