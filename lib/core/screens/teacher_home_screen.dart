import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../modules/duty/models/duty_assignment.dart';
import '../../modules/duty/models/duty_task_assignment.dart';
import '../../modules/duty/providers/duty_assignment_provider.dart';
import '../../modules/duty/screens/duty_schedule_screen.dart';
import '../../modules/duty/screens/widgets/duty_swap_requests_section.dart';
import '../../modules/duty/services/duty_cloudinary_service.dart';
import '../../modules/duty/utils/duty_time_utils.dart';
import '../../modules/teachers/models/teacher.dart';
import '../../modules/leave/screens/leave_screen.dart';
import '../../modules/report/screens/teacher_report_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
  final TeacherRecord user;
  const TeacherHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyAssignmentProvider>();
    if (provider.currentUserId != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<DutyAssignmentProvider>().setUser(
              userId: user.id,
              role: user.role,
            );
      });
    }
    final nextAssignment = provider.nextUpcomingDutyAssignment;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScoreRing(score: user.currentScore),
          const SizedBox(height: 32),
          Row(
            children: [
              _ShortcutCard(
                  title: 'Reports',
                  icon: LucideIcons.clipboardList,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TeacherReportScreen(user: user),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ShortcutCard(
                title: 'Leaves',
                icon: LucideIcons.calendarOff,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LeaveScreen(teacher: user)),
                ),
              ),
              const SizedBox(width: 12),
              _ShortcutCard(
                title: 'Schedules',
                icon: LucideIcons.calendarDays,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DutyScheduleScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          DutySwapRequestsSection(teacherId: user.id),
          const Text(
            'Next Duty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (provider.isLoadingNextDuty)
            const Center(child: CircularProgressIndicator())
          else if (provider.error != null)
            _ErrorCard(message: provider.error!)
          else if (nextAssignment == null)
            const _EmptyCard(message: 'No upcoming duty assigned.')
          else
            _DutyCard(assignment: nextAssignment, userId: user.id),
        ],
      ),
    );
  }
}

// ── Score ring ──────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 200,
        width: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 16,
              backgroundColor: const Color(0xFFBCCCDC).withValues(alpha: 0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFBCCCDC)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const Text(
                    '/100 pts',
                    style:
                        TextStyle(fontSize: 16, color: AppTheme.textLightColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Eval Score',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shortcut card ────────────────────────────────────────────────────────────

class _ShortcutCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Duty card ────────────────────────────────────────────────────────────────

class _DutyCard extends StatelessWidget {
  final DutyAssignment assignment;
  final String userId;

  const _DutyCard({required this.assignment, required this.userId});

  @override
  Widget build(BuildContext context) {
    final locationLabel = assignment.locationNameSnapshot;
    final isCompleted = assignment.status == DutyAssignmentStatus.completed;
    final canUpdate = DutyTimeUtils.isWithinUpdateWindow(
      assignment.date,
      assignment.timeStart,
      assignment.timeEnd,
    );

    return GestureDetector(
      onTap: () => _showTaskList(context),
      child: Card(
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
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      assignment.dutyNameSnapshot,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _StatusBadge(isCompleted: isCompleted),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$locationLabel  •  ${assignment.timeStart} - ${assignment.timeEnd}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    canUpdate ? 'Open task list' : 'View task list',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskListSheet(assignment: assignment, userId: userId),
    );
  }
}

// ── Task list sheet ──────────────────────────────────────────────────────────

class _TaskListSheet extends StatelessWidget {
  const _TaskListSheet({required this.assignment, required this.userId});

  final DutyAssignment assignment;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyAssignmentProvider>();
    final tasks = provider.tasksForAssignment(assignment.id);
    final canUpdate = DutyTimeUtils.isWithinUpdateWindow(
      assignment.date,
      assignment.timeStart,
      assignment.timeEnd,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.dutyNameSnapshot,
              style: Theme.of(context).textTheme.titleLarge),
          Text(
            '${assignment.timeStart} - ${assignment.timeEnd}  •  '
            '${assignment.locationNameSnapshot}',
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Text(
              'No tasks available',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...tasks.map(
              (task) => _TaskTile(
                task: task,
                userId: userId,
                canComplete: canUpdate,
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Task tile ────────────────────────────────────────────────────────────────

class _TaskTile extends StatefulWidget {
  final DutyTaskAssignment task;
  final String userId;
  final bool canComplete;

  const _TaskTile({
    required this.task,
    required this.userId,
    required this.canComplete,
  });

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _uploading = false;

  Future<void> _captureProof(BuildContext context) async {
    final provider = context.read<DutyAssignmentProvider>();
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 78, maxWidth: 1600);
    if (image == null) return;

    setState(() => _uploading = true);

    final bytes = await image.readAsBytes();
    final photoUrl = await DutyCloudinaryService.uploadTaskProof(bytes, image.name);

    if (!mounted) return;
    setState(() => _uploading = false);

    if (photoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload failed. Please try again.')),
      );
      return;
    }

    if (!context.mounted) return;
    await provider.completeTask(
      taskAssignmentId: widget.task.id,
      teacherId: widget.userId,
      photoUrl: photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: task.photoUrl != null && task.photoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                task.photoUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          : Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : Colors.grey,
            ),
      title: Text(
        task.taskNameSnapshot,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: task.isCompleted && task.completedAt != null
          ? Text(
              'Done at ${DateFormat.jm().format(task.completedAt!)}',
              style: const TextStyle(fontSize: 12),
            )
          : const Text(
              'Needs camera proof',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
      trailing: !task.isCompleted && widget.canComplete
          ? (_uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: 'Capture proof',
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: () => _captureProof(context),
                ))
          : null,
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isCompleted;
  const _StatusBadge({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isCompleted ? 'COMPLETED' : 'TODO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isCompleted ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}

// ── Utility cards ─────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}