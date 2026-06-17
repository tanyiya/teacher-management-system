import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';
import '../models/duty.dart';
import '../models/training.dart';
import '../models/notification.dart';
import '../app_theme.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  final DatabaseService _db = DatabaseService();

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
            onPressed: () {
              appState.logout();
              // Router will naturally pop back to login if not authenticated or we can explicitly go
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TeacherHomeTab(user: user, db: _db),
          _TeacherTrainingTab(user: user, db: _db),
          _TeacherPerformanceTab(user: user, db: _db),
          _TeacherAlertsTab(user: user, db: _db),
          _TeacherProfileTab(user: user, db: _db),
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
                stream: _db.getNotifications(user.id),
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

// ==============================================================================
// 1. HOME TAB
// ==============================================================================
class _TeacherHomeTab extends StatelessWidget {
  final TeacherRecord user;
  final DatabaseService db;

  const _TeacherHomeTab({Key? key, required this.user, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Radial KPI Gauge
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: user.currentScore / 100,
                    strokeWidth: 16,
                    backgroundColor: const Color(0xFFBCCCDC).withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBCCCDC)),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${user.currentScore}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                        ),
                        const Text(
                          '/100 pts',
                          style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
                        ),
                        const SizedBox(height: 8),
                        const Text('Eval Score', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Shortcuts Grid Panel
          Row(
            children: [
              _buildShortcutCard(
                context, 
                title: 'File Report', 
                icon: LucideIcons.alertTriangle, 
                onTap: () => _showReportForm(context)
              ),
              const SizedBox(width: 12),
              _buildShortcutCard(
                context, 
                title: 'Leaves', 
                icon: LucideIcons.calendarOff, 
                onTap: () => _showLeaveForm(context)
              ),
              const SizedBox(width: 12),
              _buildShortcutCard(
                context, 
                title: 'Schedules', 
                icon: LucideIcons.calendarDays, 
                onTap: () {
                  // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedules not implemented yet')));
                }
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Daily Duty Roster Checklist
          const Text('Daily Duty Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<DutyAssignment>>(
            stream: db.getAssignmentsForDate(DateFormat('yyyy-MM-dd').format(DateTime.now())),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No duties assigned for today.")));
              }
              
              final myDuties = snapshot.data!.where((d) => d.teacherIds.contains(user.id)).toList();
              if (myDuties.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No duties assigned for today.")));
              }

              return Column(
                children: myDuties.map((duty) => _buildDutyCard(context, duty)).toList(),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildShortcutCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0EFEC)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
            ]
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDutyCard(BuildContext context, DutyAssignment duty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0EFEC)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(duty.taskName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: duty.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    duty.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: duty.status == 'completed' ? Colors.green : Colors.orange,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text('${duty.locationName} • ${duty.timeStart} - ${duty.timeEnd}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...duty.checklist.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Checkbox(
                value: item.isCompleted,
                onChanged: item.isCompleted ? null : (val) async {
                  if (val == true) {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.camera);
                    if (photo != null) {
                      // Mocking photo upload: in reality, upload to Firebase Storage and get URL.
                      final updatedChecklist = duty.checklist.map((c) {
                        if (c.id == item.id) {
                          return DutyChecklistItem(
                            id: c.id,
                            description: c.description,
                            isCompleted: true,
                            photoUrl: 'base64_mock_${photo.path}',
                            completedAt: DateTime.now(),
                          );
                        }
                        return c;
                      }).toList();
                      
                      final allCompleted = updatedChecklist.every((c) => c.isCompleted);
                      
                      final updatedDuty = DutyAssignment(
                        id: duty.id,
                        taskId: duty.taskId,
                        taskName: duty.taskName,
                        date: duty.date,
                        locationId: duty.locationId,
                        locationName: duty.locationName,
                        teacherIds: duty.teacherIds,
                        status: allCompleted ? 'completed' : 'in-progress',
                        timeStart: duty.timeStart,
                        timeEnd: duty.timeEnd,
                        isReplacement: duty.isReplacement,
                        checklist: updatedChecklist,
                      );
                      
                      await db.updateAssignment(updatedDuty);
                    }
                  }
                },
              ),
              title: Text(item.description, style: TextStyle(decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
              trailing: item.photoUrl != null ? const Icon(Icons.image, color: Colors.green) : null,
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _showReportForm(BuildContext context) {
    // Basic modal for filing a report
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File Facility Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.paperclip),
              label: const Text('Attach File'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Submit Report'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      )
    );
  }

  void _showLeaveForm(BuildContext context) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Leave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Submit Leave Request'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      )
    );
  }
}

// ==============================================================================
// 2. TRAINING TAB
// ==============================================================================
class _TeacherTrainingTab extends StatefulWidget {
  final TeacherRecord user;
  final DatabaseService db;
  const _TeacherTrainingTab({Key? key, required this.user, required this.db}) : super(key: key);

  @override
  State<_TeacherTrainingTab> createState() => _TeacherTrainingTabState();
}

class _TeacherTrainingTabState extends State<_TeacherTrainingTab> {
  bool _isCreatorExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search posts, training, authors...',
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        // Expandable Creator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: InkWell(
            onTap: () => setState(() => _isCreatorExpanded = !_isCreatorExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0EFEC)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 16, child: Text(widget.user.fullName[0])),
                      const SizedBox(width: 12),
                      const Text('Share something...', style: TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Icon(_isCreatorExpanded ? LucideIcons.chevronUp : LucideIcons.plusCircle, color: AppTheme.primaryColor),
                    ],
                  ),
                  if (_isCreatorExpanded) ...[
                    const SizedBox(height: 16),
                    const TextField(
                      maxLines: 3,
                      decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Write here...'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(icon: const Icon(LucideIcons.list), onPressed: () {}),
                        IconButton(icon: const Icon(LucideIcons.link), onPressed: () {}),
                        IconButton(icon: const Icon(LucideIcons.image), onPressed: () {}),
                        const Spacer(),
                        ElevatedButton(onPressed: () {}, child: const Text('Post')),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
        
        // Feed
        Expanded(
          child: StreamBuilder<List<TrainingPost>>(
            stream: widget.db.getTrainingPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No posts yet."));
              
              final posts = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(posts[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(TrainingPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF0EFEC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(post.authorName[0])),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(post.authorRole, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Text(DateFormat('MMM dd').format(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (post.isTraining)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.graduationCap, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(post.trainingTitle ?? 'CPD Session', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Seats: ${post.traineeIds.length} / ${post.maxTrainees ?? "\u221E"}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                        onPressed: post.traineeIds.length >= (post.maxTrainees ?? 999) ? null : () {},
                        child: Text(post.traineeIds.length >= (post.maxTrainees ?? 999) ? '🚫 Fully Booked' : 'Apply to Become Trainee'),
                      ),
                    ),
                  ],
                ),
              ),
            Text(post.content),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                IconButton(icon: Icon(post.likes.contains(widget.user.id) ? Icons.thumb_up : Icons.thumb_up_outlined), onPressed: () {}),
                Text('${post.likes.length}'),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(LucideIcons.messageSquare), onPressed: () {}),
                Text('${post.commentsCount}'),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 3. PERFORMANCE TAB
// ==============================================================================
class _TeacherPerformanceTab extends StatelessWidget {
  final TeacherRecord user;
  final DatabaseService db;
  const _TeacherPerformanceTab({Key? key, required this.user, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0EFEC)),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Text('M${val.toInt()}'),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 75), FlSpot(2, 78), FlSpot(3, 82), 
                      FlSpot(4, 80), FlSpot(5, 85), FlSpot(6, 85)
                    ],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.1)),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Disciplinary Warnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0EFEC)),
            ),
            child: const Center(child: Text('No written warnings.', style: TextStyle(color: Colors.grey))),
          )
        ],
      ),
    );
  }
}

// ==============================================================================
// 4. ALERTS TAB
// ==============================================================================
class _TeacherAlertsTab extends StatelessWidget {
  final TeacherRecord user;
  final DatabaseService db;
  const _TeacherAlertsTab({Key? key, required this.user, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertNotification>>(
      stream: db.getNotifications(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No alerts."));

        final alerts = snapshot.data!;
        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Dismissible(
              key: Key(alert.id),
              direction: DismissDirection.startToEnd,
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(LucideIcons.check, color: Colors.white),
              ),
              onDismissed: (_) {
                // db.markAlertRead(alert.id); // Assuming this method exists
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: alert.isRead ? Colors.grey.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(LucideIcons.bell, color: alert.isRead ? Colors.grey : AppTheme.primaryColor),
                ),
                title: Text(alert.title, style: TextStyle(fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(alert.message),
                trailing: Text(DateFormat('HH:mm').format(alert.timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }
}

// ==============================================================================
// 5. PROFILE TAB
// ==============================================================================
class _TeacherProfileTab extends StatelessWidget {
  final TeacherRecord user;
  final DatabaseService db;
  const _TeacherProfileTab({Key? key, required this.user, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Text(user.fullName[0], style: const TextStyle(fontSize: 24, color: AppTheme.primaryColor))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      Text(user.role, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: user.completionProgress / 100, backgroundColor: Colors.black26, valueColor: const AlwaysStoppedAnimation(Colors.white)),
                      const SizedBox(height: 4),
                      Text('Profile ${user.completionProgress}% Complete', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField('Address', user.address),
          const SizedBox(height: 12),
          _buildTextField('Phone Number', user.phoneNumber),
          const SizedBox(height: 12),
          _buildTextField('Emergency Contact', user.emergencyContactName),
          const SizedBox(height: 32),
          const Text('Corporate Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildDocCard('MyKad', user.documents['myKad']),
          _buildDocCard('Resume', user.documents['resume']),
          _buildDocCard('Medical Checkup', user.documents['medicalReport']),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDocCard(String title, DocumentRecord? doc) {
    bool isUploaded = doc != null && doc.status != 'empty';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFF0EFEC))),
      child: ListTile(
        leading: Icon(LucideIcons.fileText, color: isUploaded ? Colors.green : Colors.grey),
        title: Text(title),
        subtitle: Text(isUploaded ? 'Uploaded' : 'Missing', style: TextStyle(color: isUploaded ? Colors.green : Colors.red)),
        trailing: ElevatedButton(
          onPressed: () async {
            await FilePicker.platform.pickFiles();
          },
          child: const Text('Upload'),
        ),
      ),
    );
  }
}
