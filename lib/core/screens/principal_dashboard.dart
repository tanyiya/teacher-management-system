import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state_provider.dart';
import '../../app_theme.dart';
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
        title: const Text('Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => Navigator.of(context).canPop() ? context.go('/logout') : context.go('/logout'),
          )
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) => setState(() => _currentIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor),
            selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: AppTheme.textLightColor),
            destinations: const [
              NavigationRailDestination(icon: Icon(LucideIcons.home), label: Text('Home')),
              NavigationRailDestination(icon: Icon(LucideIcons.bookOpen), label: Text('Training')),
              NavigationRailDestination(icon: Icon(LucideIcons.calendarDays), label: Text('Schedule')),
              NavigationRailDestination(icon: Icon(LucideIcons.barChart2), label: Text('KPI')),
              NavigationRailDestination(icon: Icon(LucideIcons.calendarOff), label: Text('Leaves')),
              NavigationRailDestination(icon: Icon(LucideIcons.alertTriangle), label: Text('Reports')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFF0EFEC)),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const TeacherDirectoryScreen(),
                AdminTrainingScreen(user: user),
                const DutyScheduleScreen(),
                const KpiScreen(),
                const LeaveScreen(),
                const ReportScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}