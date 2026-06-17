import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/principal_dashboard.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/teacher',
      builder: (context, state) => const TeacherDashboard(),
    ),
    GoRoute(
      path: '/principal',
      builder: (context, state) => const PrincipalDashboard(),
    ),
  ],
);
