import 'package:go_router/go_router.dart';

import 'core/screens/login_screen.dart';
import 'core/screens/teacher_dashboard.dart';
import 'core/screens/principal_dashboard.dart';
import 'core/screens/logout_screen.dart';

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
      path: '/logout',
      builder: (context, state) => const LogoutScreen(),
    ),
    GoRoute(
      path: '/principal',
      builder: (context, state) => const PrincipalDashboard(),
    ),
  ],
);
