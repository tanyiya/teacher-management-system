import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Mock Screens to satisfy routing initial bounds
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Login Gateway')));
}
class TeacherDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Teacher Dashboard')));
}
class PrincipalDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Principal Dashboard')));
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/teacher',
      builder: (context, state) => TeacherDashboard(),
    ),
    GoRoute(
      path: '/principal',
      builder: (context, state) => PrincipalDashboard(),
    ),
  ],
);
