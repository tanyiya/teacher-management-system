import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state_provider.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../../app_theme.dart';
import 'teacher_home_screen.dart';
import '../../modules/training/screens/teacher_training_screen.dart';
import '../../modules/performance/screens/performance_screen.dart';
import 'alerts_screen.dart';
import '../../modules/teachers/screens/profile_screen.dart';
import '../../modules/report/screens/teacher_report_screen.dart';
import '../../modules/leave/screens/leave_screen.dart';
import '../../modules/duty/screens/duty_schedule_screen.dart';
import '../../modules/teachers/models/teacher.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();

  // Sends the teacher to wherever a notification is actually about. Types
  // tied to the teacher's own record (documents, verification, identity
  // changes) just switch tabs; KPI/training likewise. Leave and duty/swap
  // notifications don't have a dedicated tab, so they push the existing
  // screen the same way the Home screen's quick-actions do.
  void _handleNotificationTap(TeacherRecord user, AlertNotification notif) {
    switch (notif.type) {
      case 'document_verified':
      case 'document_rejected':
      case 'record_approved':
      case 'record_rejected':
      case 'change_approved':
      case 'change_rejected':
        setState(() => _currentIndex = 4); // Profile tab
        break;
      case 'warning':
      case 'kpi':
        setState(() => _currentIndex = 2); // Performance tab
        break;
      case 'training':
      case 'broadcast':
        setState(() => _currentIndex = 1); // Training tab
        break;
      case 'leave':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => LeaveScreen(teacher: user)));
        break;
      case 'duty':
      case 'swap_request':
      case 'swap_approved':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DutyScheduleScreen()));
        break;
      default:
        break;
    }
  }

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
          AlertsScreen(
            user: user,
            onNotificationTap: (notif) => _handleNotificationTap(user, notif),
          ),
          ProfileScreen(user: user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 12)
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