import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../modules/duty/models/duty.dart';
import '../../modules/duty/services/duty_service.dart';
import '../../modules/teachers/models/teacher.dart';
import '../../app_theme.dart';

class TeacherHomeScreen extends StatelessWidget {
  final TeacherRecord user;
  const TeacherHomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DutyService dutyService = DutyService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        const Text('/100 pts', style: TextStyle(fontSize: 16, color: AppTheme.textLightColor)),
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
          Row(
            children: [
              _buildShortcutCard(context, title: 'File Report', icon: LucideIcons.alertTriangle, onTap: () => _showReportForm(context)),
              const SizedBox(width: 12),
              _buildShortcutCard(context, title: 'Leaves', icon: LucideIcons.calendarOff, onTap: () => _showLeaveForm(context)),
              const SizedBox(width: 12),
              _buildShortcutCard(context, title: 'Schedules', icon: LucideIcons.calendarDays, onTap: () {}),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Daily Duty Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<DutyAssignment>>(
            stream: dutyService.getAssignmentsForDate(DateFormat('yyyy-MM-dd').format(DateTime.now())),
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
                children: myDuties.map((duty) => _buildDutyCard(context, duty, dutyService)).toList(),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]
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

  Widget _buildDutyCard(BuildContext context, DutyAssignment duty, DutyService dutyService) {
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

                      await dutyService.updateAssignment(updatedDuty);
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
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.paperclip), label: const Text('Attach File')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Submit Report')),
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
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Submit Leave Request')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      )
    );
  }
}