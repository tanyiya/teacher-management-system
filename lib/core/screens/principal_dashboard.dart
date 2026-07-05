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
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: Colors.white,
            elevation: 0.5,
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
                    onPressed: () => _openNotifications(user),
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
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update leave: $e')));
    }
  }

  void _showReviewDialog(LeaveRecord leave, String status) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status.toUpperCase()} LEAVE REQUEST', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Teacher: ${leave.teacherName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text('Period: ${leave.startDate} (${leave.duration.toInt()} days)', style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'FEEDBACK / REMARKS NOTES',
                labelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 11),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLeaveReview(leave, status, notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: status == 'approved' ? const Color(0xFF2E7D32) : const Color(0xFFC62828), elevation: 0),
            child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF5A6B5A)));

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
              const Text('PENDING REVIEWS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF904060))),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF904060).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text('${pendingLeaves.length} Actionable Request(s)', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF904060))),
              )
            ],
          ),
          const SizedBox(height: 10),
          if (pendingLeaves.isEmpty)
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF7F8F7), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: const Center(child: Text('NO PENDING APPLICANTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingLeaves.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final leave = pendingLeaves[index];
                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE9ECE9))),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(leave.teacherName.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E241E))),
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: const Text('PENDING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFEF6C00))),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Type: ${leave.type.name}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5A6B5A))),
                      Text('Date Period: ${leave.startDate} to ${leave.endDate}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('Duration: ${leave.duration.toInt()} day(s)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (leave.remarks != null && leave.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFFF7F8F7), borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.all(8),
                          child: Text('Teacher Remarks: “${leave.remarks}”', style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.grey)),
                        )
                      ],
                      if (leave.documentUrl != null && leave.documentUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A6B5A).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF5A6B5A).withOpacity(0.2)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_download, size: 14, color: Color(0xFF5A6B5A)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    leave.documentName ?? 'View Attached Document',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w900, 
                                      color: Color(0xFF5A6B5A), 
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showReviewDialog(leave, 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            child: const Text('REJECT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _showReviewDialog(leave, 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), elevation: 0),
                            child: const Text('APPROVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          const Text('LEAVE ACTION LOG HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF7A8A7A))),
          const SizedBox(height: 10),
          if (historyLeaves.isEmpty)
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF7F8F7), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: const Center(child: Text('NO ARCHIVED LEAVE TRANSACTION HISTORY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey))),
            )
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE9ECE9))),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(leave.teacherName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          Container(
                            decoration: BoxDecoration(color: isApproved ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: Text(leave.status.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isApproved ? Colors.green : Colors.red)),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${leave.type.name} • ${leave.startDate} (${leave.duration.toInt()} days)', style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      if (leave.principalNotes != null && leave.principalNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Feedback: “${leave.principalNotes}”', style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.grey)),
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