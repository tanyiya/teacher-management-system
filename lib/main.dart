import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'providers/app_state_provider.dart';
import 'modules/duty/providers/duty_provider.dart';
import 'modules/performance/providers/performance_provider.dart';
import 'modules/training/providers/training_provider.dart';
import 'core/services/database_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initFirebase();
  final appStateProvider = AppStateProvider();
  final router = createAppRouter(appStateProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appStateProvider),
        ChangeNotifierProvider(create: (_) => DutyProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceProvider()),
        ChangeNotifierProvider(create: (_) => TrainingProvider()),
      ],
      child: TeacherManagementApp(router: router),
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // App Check activation is disabled during local debug to avoid
    // network failures when App Check API / attestation is not configured
    // or when enforcement is disabled in Firebase Console. If you need to
    // enable App Check, set `enableAppCheck` to true and configure the
    // providers in Firebase Console.
    // App Check activation removed from build to avoid native attestation
    // failures while debugging on physical devices. Configure App Check in
    // Firebase Console and re-add activation when ready.

    await DatabaseSeeder.seedDatabase();
  } catch (e, stack) {
    debugPrint('Firebase init failed: $e');
    debugPrint('$stack');
  }
}

class TeacherManagementApp extends StatelessWidget {
  const TeacherManagementApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Teacher Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
