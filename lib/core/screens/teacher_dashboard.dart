import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state_provider.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../../app_theme.dart';
import '../../modules/duty/screens/teacher_home_screen.dart';
import '../../modules/training/screens/teacher_training_screen.dart';
import '../../modules/performance/screens/performance_screen.dart';
import 'alerts_screen.dart';
import '../../modules/teachers/screens/profile_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        title: Text('Welcome, ${user.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => Navigator.of(context).canPop() ? context.go('/logout') : context.go('/logout'),
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TeacherHomeScreen(user: user),
          TeacherTrainingScreen(user: user),
          PerformanceScreen(user: user),
          AlertsScreen(user: user),
          ProfileScreen(user: user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 12)
          ]
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textLightColor,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            const BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(LucideIcons.bookOpen), label: 'Training'),
            const BottomNavigationBarItem(icon: Icon(LucideIcons.barChart), label: 'Performance'),
            BottomNavigationBarItem(
              icon: StreamBuilder<List<AlertNotification>>(
                stream: _notificationService.getNotifications(user.id),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.where((n) => !n.isRead).length;
                  }
                  return Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(unreadCount.toString()),
                    child: const Icon(LucideIcons.bell),
                  );
                },
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}