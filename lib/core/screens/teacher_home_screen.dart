import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../modules/duty/models/duty.dart';
import '../../modules/duty/providers/duty_provider.dart';
import '../../modules/teachers/models/teacher.dart';

class TeacherHomeScreen extends StatelessWidget {
  final TeacherRecord user;
  const TeacherHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();

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
                title: 'File Report',
                icon: LucideIcons.alertTriangle,
                onTap: () => _showReportForm(context),
              ),
              const SizedBox(width: 12),
              _ShortcutCard(
                title: 'Leaves',
                icon: LucideIcons.calendarOff,
                onTap: () => _showLeaveForm(context),
              ),
              const SizedBox(width: 12),
              _ShortcutCard(
                title: 'Schedules',
                icon: LucideIcons.calendarDays,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Today\'s Duties',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.error != null)
            _ErrorCard(message: provider.error!)
          else if (provider.duties.isEmpty)
            const _EmptyCard(message: 'No duties assigned for today.')
          else
            ...provider.duties.map(
              (duty) => _DutyCard(duty: duty, userId: user.id),
            ),
        ],
      ),
    );
  }

  void _showReportForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Facility Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Submit Report'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLeaveForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Leave',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Submit Leave Request'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
              backgroundColor: const Color(0xFFBCCCDC).withOpacity(0.3),
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
                    style: TextStyle(
                        fontSize: 16, color: AppTheme.textLightColor),
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
                color: Colors.black.withOpacity(0.03),
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
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
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
  final Duty duty;
  final String userId;

  const _DutyCard({required this.duty, required this.userId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    final completedCount = duty.tasks.where((t) => t.isCompleted).length;
    final totalCount = duty.tasks.length;
    final locationLabel =
        duty.locations.map((l) => l.name).join(', ');

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
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    duty.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _StatusBadge(isCompleted: duty.isCompleted),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$locationLabel  •  ${duty.timeStart} - ${duty.timeEnd}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalCount == 0 ? 0 : completedCount / totalCount,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    duty.isCompleted ? Colors.green : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedCount / $totalCount tasks done',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              // Task list
              ...duty.tasks.map(
                (task) => _TaskTile(
                  task: task,
                  duty: duty,
                  canComplete: provider.canCompleteTask(duty),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Task tile ────────────────────────────────────────────────────────────────

class _TaskTile extends StatelessWidget {
  final DutyTask task;
  final Duty duty;
  final bool canComplete;

  const _TaskTile({
    required this.task,
    required this.duty,
    required this.canComplete,
  });

  Future<void> _captureProof(BuildContext context) async {
    final provider = context.read<DutyProvider>();
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 78, maxWidth: 1600);
    if (image == null) return;
    await provider.completeTask(
      duty: duty,
      taskId: task.id,
      imageBytes: await image.readAsBytes(),
      fileName: image.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: task.photoUrl != null
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
        task.name,
        style: TextStyle(
          decoration:
              task.isCompleted ? TextDecoration.lineThrough : null,
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
      trailing: !task.isCompleted && canComplete
          ? IconButton(
              tooltip: 'Capture proof',
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: () => _captureProof(context),
            )
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
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
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