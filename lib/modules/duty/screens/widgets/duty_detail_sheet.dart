import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/duty_assignment.dart';
import '../../models/duty_task_assignment.dart';
import '../../providers/duty_assignment_provider.dart';
import '../../providers/duty_provider.dart';
import '../../services/duty_photo_upload.dart';
import '../../utils/duty_time_utils.dart';
import 'duty_editor_dialog.dart';

class DutyDetailSheet extends StatefulWidget {
  const DutyDetailSheet({super.key, required this.assignment});

  final DutyAssignment assignment;

  @override
  State<DutyDetailSheet> createState() => _DutyDetailSheetState();
}

class _DutyDetailSheetState extends State<DutyDetailSheet> {
  final _picker = ImagePicker();
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final assignmentProvider = context.watch<DutyAssignmentProvider>();
    final dutyProvider = context.watch<DutyProvider>();
    // Duty is only needed for the principal's edit shortcut now -- the
    // update window uses the assignment's own time snapshot.
    final duty = dutyProvider.dutyById(widget.assignment.dutyId);

    final withinWindow = DutyTimeUtils.isWithinUpdateWindow(
      widget.assignment.date,
      widget.assignment.timeStart,
      widget.assignment.timeEnd,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.assignment.dutyNameSnapshot,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (dutyProvider.isPrincipal && duty != null)
                IconButton(
                  tooltip: 'Edit duty',
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => DutyEditorDialog(duty: duty),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          Text(
            '${DateFormat.yMMMd().format(widget.assignment.date)}'
            '  ${widget.assignment.timeStart} - ${widget.assignment.timeEnd}',
          ),
          if (!withinWindow)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Task progress can only be updated from 30 minutes before '
                'to 30 minutes after the duty window.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Text('Venue and teachers',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(widget.assignment.locationNameSnapshot),
            subtitle: Text(widget.assignment.teacherNameSnapshots.join(', ')),
          ),
          const SizedBox(height: 12),
          Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          // Deliberately NOT `assignmentProvider.tasksForAssignment(...)` --
          // that cache is scoped to the current signed-in teacher's own
          // tasks (right for the home screen's "my next duty" card), which
          // meant opening details for anyone else's duty (or as principal)
          // always showed "no tasks". This goes straight to the
          // assignment-scoped stream instead.
          StreamBuilder<List<DutyTaskAssignment>>(
            stream: assignmentProvider.watchTasksForAssignment(widget.assignment.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Could not load tasks: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No tasks assigned.', style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: tasks
                    .map(
                      (task) => _TaskRow(
                        task: task,
                        canUpdate: withinWindow,
                        uploading: _uploading,
                        onComplete: () => _completeTask(context, task),
                        onReopen: () => context
                            .read<DutyAssignmentProvider>()
                            .reopenTask(task.id),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _completeTask(
    BuildContext context,
    DutyTaskAssignment task,
  ) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (image == null) return;

    setState(() => _uploading = true);

    // try/finally so `_uploading` always resets -- previously any
    // unexpected exception here (a network error, a read failure, etc.)
    // would skip straight past the `setState(() => _uploading = false)`
    // below and leave the capture button stuck showing a spinner forever.
    try {
      final bytes = await image.readAsBytes();
      final photoUrl = await uploadDutyProofPhoto(bytes, image.name);

      if (photoUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo upload failed. Please try again.')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      await context.read<DutyAssignmentProvider>().completeTask(
            taskAssignmentId: task.id,
            teacherId: context.read<DutyProvider>().currentUserId ?? '',
            photoUrl: photoUrl,
          );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.canUpdate,
    required this.uploading,
    required this.onComplete,
    required this.onReopen,
  });

  final DutyTaskAssignment task;
  final bool canUpdate;
  final bool uploading;
  final VoidCallback onComplete;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: task.photoUrl == null || task.photoUrl!.isEmpty
          ? Icon(task.isCompleted
              ? Icons.check_circle
              : Icons.radio_button_unchecked)
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(task.photoUrl!,
                  width: 44, height: 44, fit: BoxFit.cover),
            ),
      title: Text(task.taskNameSnapshot),
      subtitle: Text(
        task.isCompleted
            ? 'Completed${task.completedAt == null ? '' : ' ${DateFormat.jm().format(task.completedAt!)}'}'
            : 'Pending proof photo',
      ),
      trailing: !canUpdate
          ? null
          : task.isCompleted
              ? IconButton(
                  tooltip: 'Reopen',
                  onPressed: onReopen,
                  icon: const Icon(Icons.undo),
                )
              : uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: 'Capture proof',
                      onPressed: onComplete,
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
    );
  }
}