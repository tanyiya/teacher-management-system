import 'package:go_router/go_router.dart';

import 'core/screens/login_screen.dart';
import 'core/screens/logout_screen.dart';
import 'core/screens/principal_dashboard.dart';
import 'core/screens/teacher_dashboard.dart';
import 'providers/app_state_provider.dart';

GoRouter createAppRouter(AppStateProvider appState) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    redirect: (context, state) {
      if (appState.isLoading) return null;

      final location = state.uri.path;
      final isLogin = location == '/';
      final isProtected = location == '/teacher' || location == '/principal' || location == '/logout';

      if (!appState.isAuthenticated && isProtected) return '/';
      if (appState.isAuthenticated && isLogin) return appState.homeRouteForCurrentUser();
      return null;
    },
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
}
