import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_state_provider.dart';
import '../../app_theme.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'alerts_screen.dart';
import '../../modules/teachers/models/teacher.dart';
import '../../modules/teachers/screens/teacher_directory_screen.dart';
import '../../modules/training/screens/admin_training_screen.dart';
import '../../modules/duty/screens/duty_schedule_screen.dart';
import '../../modules/performance/screens/kpi_screen.dart';
import '../../modules/leave/screens/leave_screen.dart';
import '../../modules/report/screens/my_reports_screen.dart';
import '../../modules/leave/models/leave.dart' hide TeacherRecord;
import '../../modules/leave/services/leave_service.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({Key? key}) : super(key: key);

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  int _currentIndex = 0;
  final NotificationService _notifSvc = NotificationService();

  // Set when a notification (e.g. a change request) is tapped, so the
  // Teachers tab can jump straight to that teacher's case. The token forces
  // TeacherDirectoryScreen to rebuild fresh even if the same teacher is
  // opened twice in a row.
  String? _pendingTeacherId;
  int _pendingTeacherTab = 0;
  int _caseRequestToken = 0;

  // Same idea, for jumping straight to a specific incident report when its
  // notification is tapped.
  String? _pendingReportId;
  int _reportRequestToken = 0;

  void _goTo(int index) => setState(() => _currentIndex = index);

  void _openNotifications(TeacherRecord user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppTheme.canvasBase,
          appBar: AppBar(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: AppTheme.cardBackground,
            elevation: 0,
            shape: const Border(bottom: BorderSide(color: AppTheme.subtleGrayBoundary)),
          ),
          body: AlertsScreen(user: user, onNotificationTap: _handleNotificationTap),
        ),
      ),
    );
  }

  // Decides where a tapped notification should take the admin, closing the
  // Notifications page first and then switching to the relevant tab.
  void _handleNotificationTap(AlertNotification notif) {
    switch (notif.type) {
      case 'change_request':
        if (notif.relatedId.isEmpty) return;
        Navigator.pop(context);
        setState(() {
          _pendingTeacherId = notif.relatedId;
          _pendingTeacherTab = 2; // Change Requests tab
          _caseRequestToken++;
          _currentIndex = 1; // Teachers tab
        });
        break;
      case 'new_registration':
        if (notif.relatedId.isEmpty) return;
        Navigator.pop(context);
        setState(() {
          _pendingTeacherId = notif.relatedId;
          _pendingTeacherTab = 0; // Profile tab (registration approve/reject lives in the header)
          _caseRequestToken++;
          _currentIndex = 1; // Teachers tab
        });
        break;
      case 'leave':
        Navigator.pop(context);
        setState(() => _currentIndex = 5); // Leave Management tab
        break;
      case 'incident_report':
        if (notif.relatedId.isEmpty) return;
        Navigator.pop(context);
        setState(() {
          _pendingReportId = notif.relatedId;
          _reportRequestToken++;
          _currentIndex = 6; // Reports tab
        });
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

    final List<Widget> screens = [
      _AdminHomeScreen(user: user, onNavigate: _goTo),
      TeacherDirectoryScreen(
        key: _pendingTeacherId == null ? null : ValueKey('teachers-$_caseRequestToken'),
        initialTeacherId: _pendingTeacherId,
        initialTab: _pendingTeacherTab,
      ),
      AdminTrainingScreen(user: user),
      const DutyScheduleScreen(),
      const KpiScreen(),
      const _AdminLeaveManagementScreen(),
      ReportScreen(
        key: _pendingReportId == null ? null : ValueKey('report-$_reportRequestToken'),
        initialReportId: _pendingReportId,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: AppTheme.canvasBase,
          appBar: AppBar(
            title: const Text('Admin Portal',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.schoolDarkBlue)),
            backgroundColor: AppTheme.cardBackground,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: AppTheme.schoolDarkBlue.withValues(alpha: 0.08),
            shape: const Border(bottom: BorderSide(color: AppTheme.subtleGrayBoundary)),
            actions: [
              StreamBuilder<List<AlertNotification>>(
                stream: _notifSvc.getNotifications(user.id),
                builder: (context, snap) {
                  final unread = snap.data?.where((n) => !n.isRead).length ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => _openNotifications(user),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.schoolBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Badge(
                          backgroundColor: AppTheme.schoolOrange,
                          isLabelVisible: unread > 0,
                          label: Text(unread > 9 ? '9+' : '$unread'),
                          child: const Icon(LucideIcons.bell, size: 19, color: AppTheme.schoolDarkBlue),
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.logOut, color: AppTheme.schoolOrange, size: 20),
                tooltip: 'Log Out',
                onPressed: () => context.go('/logout'),
              ),
              const SizedBox(width: 8),
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
                      backgroundColor: AppTheme.cardBackground,
                      indicatorColor: AppTheme.schoolBlue.withValues(alpha: 0.10),
                      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      selectedIconTheme:
                          const IconThemeData(color: AppTheme.schoolBlue, size: 20),
                      selectedLabelTextStyle: const TextStyle(
                          color: AppTheme.schoolBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      unselectedIconTheme:
                          const IconThemeData(color: AppTheme.textMuted, size: 20),
                      unselectedLabelTextStyle:
                          const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
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
                        thickness: 1, width: 1, color: AppTheme.subtleGrayBoundary),
                    Expanded(
                        child: IndexedStack(
                            index: _currentIndex, children: screens)),
                  ],
                ),
          bottomNavigationBar: isNarrow
              ? Container(
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
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: AppTheme.cardBackground,
                      currentIndex: _currentIndex,
                      onTap: _goTo,
                      elevation: 0,
                      selectedItemColor: AppTheme.schoolBlue,
                      unselectedItemColor: AppTheme.textMuted,
                      selectedFontSize: 10,
                      unselectedFontSize: 10,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      items: const [
                        BottomNavigationBarItem(
                            icon: Icon(LucideIcons.home, size: 18), label: 'Home'),
                        BottomNavigationBarItem(
                            icon: Icon(LucideIcons.users, size: 18), label: 'Teachers'),
                        BottomNavigationBarItem(
                            icon: Icon(LucideIcons.bookOpen, size: 18), label: 'Training'),
                        BottomNavigationBarItem(
                            icon: Icon(LucideIcons.calendarDays, size: 18),
                            label: 'Schedule'),
                        BottomNavigationBarItem(
                            icon: Icon(LucideIcons.barChart2, size: 18), label: 'KPI'),
                        BottomNavigationBarItem(
                            icon: Icon(LucideIcons.calendarOff, size: 18), label: 'Leaves'),
                        BottomNavigationBarItem(
                            icon: Icon(LucideIcons.alertTriangle, size: 18),
                            label: 'Reports'),
                      ],
                    ),
                  ),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = user.fullName as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome banner ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.schoolBlue,
                  AppTheme.schoolDarkBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.schoolBlue.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Text(
                    _initials(fullName),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $fullName',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin Portal — manage your school from here.',
                        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
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
                  'View & manage records', AppTheme.schoolBlue, () => onNavigate(1)),
              _quickCard(context, LucideIcons.bookOpen, 'Training',
                  'Manage training posts', Colors.indigo, () => onNavigate(2)),
              _quickCard(context, LucideIcons.calendarDays, 'Schedule',
                  'Duty assignments', Colors.teal, () => onNavigate(3)),
              _quickCard(context, LucideIcons.barChart2, 'KPI',
                  'Performance scores', AppTheme.schoolOrange, () => onNavigate(4)),
              _quickCard(context, LucideIcons.calendarOff, 'Leaves',
                  'Leave requests', Colors.purple, () => onNavigate(5)),
              _quickCard(context, LucideIcons.alertTriangle, 'Reports',
                  'Incident reports', const Color(0xFFD32F2F), () => onNavigate(6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.schoolBlue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.schoolDarkBlue),
          ),
        ],
      );

  Widget _quickCard(BuildContext context, IconData icon, String title,
      String subtitle, Color color, VoidCallback onTap) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.subtleGrayBoundary),
            boxShadow: [
              BoxShadow(
                color: AppTheme.schoolDarkBlue.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  Icon(LucideIcons.chevronRight, size: 15, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                ],
              ),
              const Spacer(),
              Text(title,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textCore)),
              const SizedBox(height: 2),
              Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin Leave Management UI ────────────────────────────────────────────────

class _AdminLeaveManagementScreen extends StatefulWidget {
  const _AdminLeaveManagementScreen({Key? key}) : super(key: key);

  @override
  __AdminLeaveManagementScreenState createState() => __AdminLeaveManagementScreenState();
}

class __AdminLeaveManagementScreenState extends State<_AdminLeaveManagementScreen> {
  final LeaveService _leaveService = LeaveService();
  List<LeaveRecord> _allLeaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeLeaves();
  }

  void _subscribeLeaves() {
    _leaveService.getLeaves(teacherId: null).listen((leaves) {
      if (mounted) {
        setState(() {
          _allLeaves = leaves;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleLeaveReview(LeaveRecord leave, String status, String notes) async {
    try {
      await _leaveService.updateLeaveStatus(
        leaveId: leave.id,
        status: status,
        principalNotes: notes,
        teacherId: leave.teacherId,
        leaveType: leave.type.name,
        duration: leave.duration,
        startDate: leave.startDate,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully $status leave request from ${leave.teacherName}.'),
          backgroundColor: status == 'approved' ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update leave: $e')));
    }
  }

  void _showReviewDialog(LeaveRecord leave, String status) {
    final notesController = TextEditingController();
    final bool isApprove = status == 'approved';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isApprove ? const Color(0xFF2E7D32) : const Color(0xFFC62828)).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApprove ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                size: 16,
                color: isApprove ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              ),
            ),
            const SizedBox(width: 10),
            Text('${status.toUpperCase()} LEAVE REQUEST',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: AppTheme.schoolDarkBlue)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Teacher: ${leave.teacherName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textCore)),
            const SizedBox(height: 4),
            Text('Period: ${leave.startDate} (${leave.duration.toInt()} days)', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, color: AppTheme.textCore),
              decoration: InputDecoration(
                labelText: 'FEEDBACK / REMARKS NOTES',
                labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted),
                fillColor: AppTheme.ambientOffWhite,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.subtleGrayBoundary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.schoolBlue, width: 1.5),
                ),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
            child: const Text('CANCEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLeaveReview(leave, status, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? const Color(0xFF2E7D32) : const Color(0xFFC62828), 
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _emptyState(IconData icon, String message) => Container(
        decoration: BoxDecoration(
          color: AppTheme.ambientOffWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.subtleGrayBoundary),
        ),
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              Text(message,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: AppTheme.textMuted)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.schoolBlue));

    final pendingLeaves = _allLeaves.where((l) => l.status == 'pending').toList();
    final historyLeaves = _allLeaves.where((l) => l.status != 'pending').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: Color(0xFF904060)),
                  const SizedBox(width: 6),
                  const Text('PENDING REVIEWS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF904060))),
                ],
              ),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF904060).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text('${pendingLeaves.length} Actionable Request(s)', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF904060))),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (pendingLeaves.isEmpty)
            _emptyState(LucideIcons.calendarCheck, 'NO PENDING APPLICANTS')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingLeaves.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final leave = pendingLeaves[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground, 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: AppTheme.subtleGrayBoundary),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.schoolDarkBlue.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.schoolBlue.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _initials(leave.teacherName),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.schoolBlue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(leave.teacherName.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.schoolDarkBlue)),
                          ),
                          Container(
                            decoration: BoxDecoration(color: AppTheme.schoolLightOrange, borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(LucideIcons.clock, size: 10, color: AppTheme.schoolOrange),
                                SizedBox(width: 4),
                                Text('PENDING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.schoolOrange)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.ambientOffWhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.fileText, size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text('Type: ${leave.type.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textCore)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.calendarRange, size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('${leave.startDate} to ${leave.endDate}  •  ${leave.duration.toInt()} day(s)',
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (leave.remarks != null && leave.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.schoolBlue.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.schoolBlue.withValues(alpha: 0.08)),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Text('Teacher Remarks: “${leave.remarks}”', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.textCore)),
                        )
                      ],
                      if (leave.documentUrl != null && leave.documentUrl!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            final url = Uri.parse(leave.documentUrl!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open document link.')),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.schoolBlue.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.schoolBlue.withValues(alpha: 0.15)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_download, size: 14, color: AppTheme.schoolBlue),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    leave.documentName ?? 'View Attached Document',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w900, 
                                      color: AppTheme.schoolBlue, 
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showReviewDialog(leave, 'rejected'),
                            icon: const Icon(LucideIcons.x, size: 13),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD32F2F), 
                              side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            label: const Text('REJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showReviewDialog(leave, 'approved'),
                            icon: const Icon(LucideIcons.check, size: 13, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32), 
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            label: const Text('APPROVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
          Row(
            children: const [
              Icon(LucideIcons.history, size: 13, color: AppTheme.textMuted),
              SizedBox(width: 6),
              Text('LEAVE ACTION LOG HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          if (historyLeaves.isEmpty)
            _emptyState(LucideIcons.archive, 'NO ARCHIVED LEAVE TRANSACTION HISTORY')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyLeaves.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final leave = historyLeaves[index];
                final isApproved = leave.status == 'approved';
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: AppTheme.subtleGrayBoundary),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: (isApproved ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)).withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _initials(leave.teacherName),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isApproved ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(leave.teacherName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textCore)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isApproved ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), 
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isApproved ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                                  size: 10,
                                  color: isApproved ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  leave.status.toUpperCase(), 
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isApproved ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${leave.type.name} • ${leave.startDate} (${leave.duration.toInt()} days)', 
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                      ),
                      if (leave.principalNotes != null && leave.principalNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Feedback: “${leave.principalNotes}”', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.textMuted)),
                      ]
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}