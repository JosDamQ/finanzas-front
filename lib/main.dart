import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/budgets_screen.dart';
import 'services/notification_service.dart';

import 'providers/card_provider.dart';
import 'providers/budget_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Firebase here once and for all
  print("DEBUG: Inicializando Firebase en main()...");
  try {
    // Check if already initialized
    try {
      Firebase.app();
      print("DEBUG: Firebase ya estaba inicializado");
    } catch (e) {
      // Not initialized, so initialize it
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("DEBUG: Firebase inicializado exitosamente en main()");
    }
  } catch (e) {
    print("DEBUG: Error con Firebase en main(): $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: MaterialApp(
        title: 'Finanzas Personales',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/budgets': (context) => const BudgetsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checkedAuth = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
    _initializeNotifications();
  }

  Future<void> _checkInitialAuth() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await context.read<AuthProvider>().checkAuth(fromSplash: true);
      setState(() {
        _checkedAuth = true;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    print("DEBUG: Iniciando inicialización de NotificationService...");

    // Wait for the widget tree to be fully built
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Firebase should already be initialized in main()
      print("DEBUG: Inicializando NotificationService...");
      await NotificationService.initialize(context: context);
      print("DEBUG: NotificationService inicializado correctamente");
    } catch (e) {
      print("DEBUG: Error inicializando NotificationService: $e");
    }
  }

  void _setupNotifications() async {
    // Handle navigation when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted) return;

      if (message.data['type'] == 'limit_warning') {
        // Assuming you have a way to get cardId from data if needed
        // For now, go to dashboard
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else if (message.data['type'] == 'budget_reminder') {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BudgetsScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Update notification service context
    NotificationService.updateContext(context);

    if (!_checkedAuth || authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
