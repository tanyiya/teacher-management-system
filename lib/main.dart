import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'providers/app_state_provider.dart';
import 'modules/duty/providers/duty_provider.dart';
import 'modules/training/providers/training_provider.dart';
import 'core/services/database_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => DutyProvider()),
        ChangeNotifierProvider(create: (_) => TrainingProvider()),
      ],
      child: const TeacherManagementApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Only seed in debug mode, and only if needed (implement a flag in seeder)
    if (kDebugMode) {
      await DatabaseSeeder.seedDatabase();
    }
  } catch (e, stack) {
    debugPrint('Firebase init failed: $e');
    debugPrint('$stack');
    // App continues — screens dependent on Firebase should handle
    // the uninitialized state gracefully via their own error handling.
  }
}

class TeacherManagementApp extends StatelessWidget {
  const TeacherManagementApp({super.key}); // prefer super.key over Key? key

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Teacher Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}