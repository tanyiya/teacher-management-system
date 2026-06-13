import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'routes.dart';
import 'providers/app_state_provider.dart';
import 'providers/duty_provider.dart';
import 'providers/training_provider.dart';
import 'services/database_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: For a real Firebase project, replace the below with proper initialization options.
  // e.g. await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await Firebase.initializeApp();
    // Optionally seed database on startup
    await DatabaseSeeder.seedDatabase();
  } catch (e) {
    print("Firebase init error (expected if no google-services file provided yet): \$e");
  }

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

class TeacherManagementApp extends StatelessWidget {
  const TeacherManagementApp({Key? key}) : super(key: key);

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
