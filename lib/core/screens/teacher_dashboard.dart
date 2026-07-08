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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  static const List<String> _tabLabels = ['Home', 'Training', 'Performance', 'Alerts', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: AppTheme.canvasBase,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.schoolBlue, AppTheme.schoolDarkBlue],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                _initials(user.fullName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.schoolDarkBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    _tabLabels[_currentIndex],
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppTheme.schoolDarkBlue.withValues(alpha: 0.08),
        shape: const Border(
          bottom: BorderSide(color: AppTheme.subtleGrayBoundary, width: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.schoolOrange.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.logOut, color: AppTheme.schoolOrange, size: 18),
              ),
              tooltip: 'Log Out',
              onPressed: () => context.go('/logout'),
            ),
          ),
          const SizedBox(width: 4),
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
          color: AppTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppTheme.schoolDarkBlue.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppTheme.subtleGrayBoundary, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.cardBackground,
            selectedItemColor: AppTheme.schoolBlue,
            unselectedItemColor: AppTheme.textMuted,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700, 
              fontSize: 11,
              color: AppTheme.schoolBlue,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
            items: [
              _navItem(LucideIcons.home, 'Home', 0),
              _navItem(LucideIcons.bookOpen, 'Training', 1),
              _navItem(LucideIcons.barChart, 'Performance', 2),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StreamBuilder<List<AlertNotification>>(
                    stream: _notificationService.getNotifications(user.id),
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData) {
                        unreadCount = snapshot.data!.where((n) => !n.isRead).length;
                      }
                      final bool selected = _currentIndex == 3;
                      return Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.schoolBlue.withValues(alpha: 0.10) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Badge(
                          backgroundColor: AppTheme.schoolOrange,
                          isLabelVisible: unreadCount > 0,
                          label: Text(
                            unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          child: const Icon(LucideIcons.bell, size: 20),
                        ),
                      );
                    },
                  ),
                ),
                label: 'Alerts',
              ),
              _navItem(LucideIcons.user, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final bool selected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.schoolBlue.withValues(alpha: 0.10) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20),
        ),
      ),
      label: label,
    );
  }
}