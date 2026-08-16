import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/budget_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/authentication_provider.dart';
import 'providers/settings_provider.dart';
import 'billing/billing_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'family_engine/providers/family_providers.dart';
import 'views/splash_screen.dart';

import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp warning: $e');
  }
  await NotificationService.instance.initialize();
  runApp(const SagiroApp());
}

class SagiroApp extends StatelessWidget {
  const SagiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => FamilyStateNotifier()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Sagiro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: settings.amoledMode
                ? AppTheme.amoledTheme
                : AppTheme.darkTheme,
            themeMode: settings.themeMode,
            builder: (context, child) {
              return DefaultTextStyle.merge(
                style: const TextStyle(
                  decoration: TextDecoration.none,
                ),
                child: child ?? const SizedBox(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// Backward-compatible alias for PaisaPilotApp and HisariApp
typedef PaisaPilotApp = SagiroApp;
typedef HisariApp = SagiroApp;
