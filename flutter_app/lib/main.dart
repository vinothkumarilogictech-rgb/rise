import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'core/constants/theme.dart';
import 'core/services/notification_service.dart';
import 'core/network/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/shell/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const RiseApp(),
    ),
  );
}

class RiseApp extends StatelessWidget {
  const RiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RISE — Personal Growth System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootGatekeeper(),
    );
  }
}

class RootGatekeeper extends StatefulWidget {
  const RootGatekeeper({super.key});

  @override
  State<RootGatekeeper> createState() => _RootGatekeeperState();
}

class _RootGatekeeperState extends State<RootGatekeeper> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    await auth.initialize();
    if (auth.isAuthenticated) {
      await app.loadAllData();
      await NotificationService().initFcm(apiClient: ApiClient());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.status == AuthStatus.initial) {
      // Elegant Splash Screen
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.terrain, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'RISE',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Personal Growth System',
                style: TextStyle(fontSize: 12, color: AppColors.cyanHighlight, letterSpacing: 1.0),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyanHighlight),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const MainNavigationShell();
    }

    if (!auth.isOnboarded) {
      return const WelcomeScreen();
    }

    return const AuthScreen(initialIsRegister: false);
  }
}
