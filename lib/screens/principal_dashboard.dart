import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';
import '../models/duty.dart';
import '../models/report.dart';
import '../app_theme.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({Key? key}) : super(key: key);

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
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
        title: const Text('Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () {
              appState.logout();
            },
          )
        ],
      ),
      body: Row(
        children: [
          // Using a NavigationRail for Principal dashboard as they have more tabs
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
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
                _AdminHomeTab(db: _db),
                _AdminTrainingTab(user: user, db: _db),
                _AdminScheduleTab(db: _db),
                _AdminKPITab(db: _db),
                _AdminLeavesTab(db: _db),
                _AdminReportsTab(db: _db),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 1. HOME TAB (Faculty Directory)
// ==============================================================================
class _AdminHomeTab extends StatelessWidget {
  final DatabaseService db;
  const _AdminHomeTab({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeacherRecord>>(
      stream: db.getTeachers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) return const Center(child: Text("No data."));

        final teachers = snapshot.data!.where((t) => t.role != 'principal' && t.role != 'admin').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Stats Bento-Grid
              Row(
                children: [
                  _buildStatCard('Total Teachers', teachers.length.toString(), LucideIcons.users),
                  const SizedBox(width: 16),
                  _buildStatCard('Active Leaves', '2', LucideIcons.calendarOff), // Mock data for now
                  const SizedBox(width: 16),
                  _buildStatCard('Resolved Incidents', '14', LucideIcons.checkCircle),
                  const SizedBox(width: 16),
                  _buildStatCard('Duty Completion %', '92%', LucideIcons.checkSquare),
                ],
              ),
              const SizedBox(height: 32),
              
              const Text('Faculty Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final t = teachers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFF0EFEC))),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(t.fullName[0])),
                      title: Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${t.role} • KPI: ${t.currentScore}/100 • Profile: ${t.completionProgress}%'),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () {
                        // Launch modal to see detailed profile
                        _showTeacherModal(context, t);
                      },
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0EFEC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showTeacherModal(BuildContext context, TeacherRecord t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${t.email}'),
            Text('Phone: ${t.phoneNumber}'),
            Text('Emergency Contact: ${t.emergencyContactName} (${t.emergencyContactNumber})'),
            const SizedBox(height: 16),
            const Text('Documents:'),
            ...t.documents.entries.map((e) => Text('- ${e.key}: ${e.value.status}')).toList(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      )
    );
  }
}

// ==============================================================================
// 2. TRAINING TAB (CPD Architecture)
// ==============================================================================
class _AdminTrainingTab extends StatefulWidget {
  final TeacherRecord user;
  final DatabaseService db;
  const _AdminTrainingTab({Key? key, required this.user, required this.db}) : super(key: key);

  @override
  State<_AdminTrainingTab> createState() => _AdminTrainingTabState();
}

class _AdminTrainingTabState extends State<_AdminTrainingTab> {
  bool _isCpd = false;
  String _recruitmentType = 'Open for Volunteers';
  final List<String> _selectedTraineeIds = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Post / CPD Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const TextField(
                maxLines: 2,
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Content...'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: _isCpd, onChanged: (v) => setState(() => _isCpd = v ?? false)),
                  const Text('Is this a Training/CPD Session?'),
                ],
              ),
              if (_isCpd) ...[
                const SizedBox(height: 12),
                const TextField(decoration: InputDecoration(labelText: 'Course Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: TextField(decoration: InputDecoration(labelText: 'Max Seats', border: OutlineInputBorder()))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _recruitmentType,
                        items: ['Open for Volunteers', 'Assign Trainees'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _recruitmentType = v!),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                if (_recruitmentType == 'Assign Trainees') ...[
                  const SizedBox(height: 12),
                  const Text('Select Trainees:'),
                  StreamBuilder<List<TeacherRecord>>(
                    stream: widget.db.getTeachers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final teachers = snapshot.data!.where((t) => t.role != 'principal').toList();
                      return Wrap(
                        spacing: 8,
                        children: teachers.map((t) => FilterChip(
                          label: Text(t.fullName),
                          selected: _selectedTraineeIds.contains(t.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTraineeIds.add(t.id);
                              } else {
                                _selectedTraineeIds.remove(t.id);
                              }
                            });
                          },
                        )).toList(),
                      );
                    },
                  )
                ]
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(onPressed: () {}, child: const Text('Post')),
              )
            ],
          ),
        ),
        const Divider(height: 1),
        const Expanded(
          child: Center(child: Text("Active registrations table will go here.")),
        )
      ],
    );
  }
}

// ==============================================================================
// 3. SCHEDULE TAB
// ==============================================================================
class _AdminScheduleTab extends StatelessWidget {
  final DatabaseService db;
  const _AdminScheduleTab({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Master Schedule', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Mock Calendar Grid
          Container(
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF0EFEC)), borderRadius: BorderRadius.circular(12)),
            child: const Text('Calendar Grid Placeholder'),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tasks for Selected Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    StreamBuilder<List<DutyAssignment>>(
                      stream: db.getAssignmentsForDate(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("No tasks.");
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final duty = snapshot.data![index];
                            return Card(
                              child: ListTile(
                                title: Text(duty.taskName),
                                subtitle: Text('${duty.locationName} • ${duty.timeStart}-${duty.timeEnd}'),
                                trailing: Text(duty.status, style: TextStyle(color: duty.status == 'completed' ? Colors.green : Colors.orange)),
                              ),
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Negotiation Swaps', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sarah wants to swap with David for Main Gate Duty.'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton(onPressed: (){}, child: const Text('Reject', style: TextStyle(color: Colors.red))),
                                ElevatedButton(onPressed: (){}, child: const Text('Accept')),
                              ],
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

// ==============================================================================
// 4. KPI TAB
// ==============================================================================
class _AdminKPITab extends StatelessWidget {
  final DatabaseService db;
  const _AdminKPITab({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KPI Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Point Allocator', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const DropdownMenu<String>(dropdownMenuEntries: [DropdownMenuEntry(value: '1', label: 'Select Teacher...')]),
                        const SizedBox(height: 16),
                        const Text('Points: +5'),
                        Slider(value: 5, min: -30, max: 10, onChanged: (v) {}),
                        const SizedBox(height: 16),
                        const TextField(decoration: InputDecoration(labelText: 'Remarks', border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: (){}, child: const Text('Allocate Points'))
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Warnings Dispatcher', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const DropdownMenu<String>(dropdownMenuEntries: [DropdownMenuEntry(value: '1', label: 'Select Teacher...')]),
                        const SizedBox(height: 16),
                        const DropdownMenu<String>(dropdownMenuEntries: [
                          DropdownMenuEntry(value: 'verbal', label: 'Verbal Warning'),
                          DropdownMenuEntry(value: 'written', label: 'Written Warning'),
                        ]),
                        const SizedBox(height: 16),
                        const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: (){}, child: const Text('Dispatch Warning'))
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

// ==============================================================================
// 5. LEAVES TAB
// ==============================================================================
class _AdminLeavesTab extends StatelessWidget {
  final DatabaseService db;
  const _AdminLeavesTab({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leave Requests Directory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          // Need a global leaves stream. Mocking it here as empty state.
          Center(child: Text('No active leave requests.'))
        ],
      ),
    );
  }
}

// ==============================================================================
// 6. REPORTS TAB
// ==============================================================================
class _AdminReportsTab extends StatelessWidget {
  final DatabaseService db;
  const _AdminReportsTab({Key? key, required this.db}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Triaging Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          StreamBuilder<List<FacilityReport>>(
            stream: db.getReports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("No reports.");

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final report = snapshot.data![index];
                  return ExpansionTile(
                    title: Text(report.description),
                    subtitle: Text('Status: ${report.status} • Priority: ${report.priority}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reported by: ${report.teacherName}'),
                            if (report.photoUrl.isNotEmpty) const Text('Photo attached.'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const DropdownMenu<String>(dropdownMenuEntries: [
                                  DropdownMenuEntry(value: 'under_review', label: 'Under Review'),
                                  DropdownMenuEntry(value: 'action_taken', label: 'Action Taken'),
                                  DropdownMenuEntry(value: 'resolved', label: 'Resolved'),
                                ]),
                                const SizedBox(width: 16),
                                ElevatedButton(onPressed: (){}, child: const Text('Update Status')),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }
}
