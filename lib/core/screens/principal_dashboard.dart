import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state_provider.dart';
import '../../app_theme.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'alerts_screen.dart';
import '../../modules/teachers/screens/teacher_directory_screen.dart';
import '../../modules/training/screens/admin_training_screen.dart';
import '../../modules/duty/screens/duty_schedule_screen.dart';
import '../../modules/performance/screens/kpi_screen.dart';
import '../../modules/leave/screens/leave_screen.dart';
import '../../modules/report/screens/report_screen.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({Key? key}) : super(key: key);

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  int _currentIndex = 0;
  final NotificationService _notifSvc = NotificationService();

  void _goTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final screens = [
      _AdminHomeScreen(user: user, onNavigate: _goTo),
      const TeacherDirectoryScreen(),
      AdminTrainingScreen(user: user),
      const DutyScheduleScreen(),
      const KpiScreen(),
      const LeaveScreen(),
      const ReportScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F3),
          appBar: AppBar(
            title: const Text('Admin Portal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: Colors.white,
            elevation: 0.5,
            actions: [
              StreamBuilder<List<AlertNotification>>(
                stream: _notifSvc.getNotifications(user.id),
                builder: (context, snap) {
                  final unread = snap.data?.where((n) => !n.isRead).length ?? 0;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text(unread > 9 ? '9+' : '$unread'),
                      child: const Icon(LucideIcons.bell),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Notifications'),
                            backgroundColor: Colors.white,
                            elevation: 0.5,
                          ),
                          body: AlertsScreen(user: user),
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.logOut),
                onPressed: () => context.go('/logout'),
              ),
            ],
          ),
          body: isNarrow
              ? IndexedStack(index: _currentIndex, children: screens)
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _goTo,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.white,
                      selectedIconTheme:
                          const IconThemeData(color: AppTheme.primaryColor),
                      selectedLabelTextStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold),
                      unselectedLabelTextStyle:
                          const TextStyle(color: AppTheme.textLightColor),
                      destinations: const [
                        NavigationRailDestination(
                            icon: Icon(LucideIcons.home),
                            label: Text('Home')),
                        NavigationRailDestination(
                            icon: Icon(LucideIcons.users),
                            label: Text('Teachers')),
                        NavigationRailDestination(
                            icon: Icon(LucideIcons.bookOpen),
                            label: Text('Training')),
                        NavigationRailDestination(
                            icon: Icon(LucideIcons.calendarDays),
                            label: Text('Schedule')),
                        NavigationRailDestination(
                            icon: Icon(LucideIcons.barChart2),
                            label: Text('KPI')),
                        NavigationRailDestination(
                            icon: Icon(LucideIcons.calendarOff),
                            label: Text('Leaves')),
                        NavigationRailDestination(
                            icon: Icon(LucideIcons.alertTriangle),
                            label: Text('Reports')),
                      ],
                    ),
                    const VerticalDivider(
                        thickness: 1, width: 1, color: Color(0xFFF0EFEC)),
                    Expanded(
                        child: IndexedStack(
                            index: _currentIndex, children: screens)),
                  ],
                ),
          bottomNavigationBar: isNarrow
              ? BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppTheme.canvasBase,
                  currentIndex: _currentIndex,
                  onTap: _goTo,
                  selectedItemColor: AppTheme.primaryColor,
                  unselectedItemColor: AppTheme.textMuted,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(LucideIcons.home), label: 'Home'),
                    BottomNavigationBarItem(
                        icon: Icon(LucideIcons.users), label: 'Teachers'),
                    BottomNavigationBarItem(
                        icon: Icon(LucideIcons.bookOpen), label: 'Training'),
                    BottomNavigationBarItem(
                        icon: Icon(LucideIcons.calendarDays),
                        label: 'Schedule'),
                    BottomNavigationBarItem(
                        icon: Icon(LucideIcons.barChart2), label: 'KPI'),
                    BottomNavigationBarItem(
                        icon: Icon(LucideIcons.calendarOff), label: 'Leaves'),
                    BottomNavigationBarItem(
                        icon: Icon(LucideIcons.alertTriangle),
                        label: 'Reports'),
                  ],
                )
              : null,
        );
      },
    );
  }
}

// ── Simple admin home screen ──────────────────────────────────────────────────

class _AdminHomeScreen extends StatelessWidget {
  final dynamic user;
  final void Function(int) onNavigate;

  const _AdminHomeScreen({required this.user, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user.fullName}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin Portal — manage your school from here.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Quick Access'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _quickCard(context, LucideIcons.users, 'Teachers',
                  'View & manage records', AppTheme.primaryColor, () => onNavigate(1)),
              _quickCard(context, LucideIcons.bookOpen, 'Training',
                  'Manage training posts', Colors.indigo, () => onNavigate(2)),
              _quickCard(context, LucideIcons.calendarDays, 'Schedule',
                  'Duty assignments', Colors.teal, () => onNavigate(3)),
              _quickCard(context, LucideIcons.barChart2, 'KPI',
                  'Performance scores', Colors.orange, () => onNavigate(4)),
              _quickCard(context, LucideIcons.calendarOff, 'Leaves',
                  'Leave requests', Colors.purple, () => onNavigate(5)),
              _quickCard(context, LucideIcons.alertTriangle, 'Reports',
                  'Incident reports', Colors.red, () => onNavigate(6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );

  Widget _quickCard(BuildContext context, IconData icon, String title,
      String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.subtleGrayBoundary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
