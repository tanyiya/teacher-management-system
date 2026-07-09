import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/duty_assignment.dart';
import '../models/duty_task_assignment.dart';
import '../providers/duty_assignment_provider.dart';
import '../providers/duty_provider.dart';
import '../providers/duty_schedule_provider.dart';
import '../utils/duty_time_utils.dart';
import 'widgets/duty_detail_sheet.dart';
import 'widgets/duty_editor_dialog.dart';
import 'widgets/duty_swap_dialog.dart';

/// Each `DutyAssignment` is now scoped to exactly one venue, so a duty with
/// multiple venues naturally produces multiple cards here -- one per venue,
/// each showing that venue's own dedicated teacher(s).
class DutyListScreen extends StatelessWidget {
  const DutyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyAssignmentProvider>();
    final dutyProvider = context.watch<DutyProvider>();
    final schedule = context.watch<DutyScheduleProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    final visible = provider.filteredAssignments(
      teacherFilterId: schedule.teacherFilterId,
      locationFilterId: schedule.locationFilterId,
      showAllTeachers: schedule.showAllTeachers,
    );
    final todo = visible
        .where((a) => a.status != DutyAssignmentStatus.completed)
        .toList();
    final completed = visible
        .where((a) => a.status == DutyAssignmentStatus.completed)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DutySection(
          title: 'TODO',
          assignments: todo,
          provider: provider,
          dutyProvider: dutyProvider,
        ),
        const SizedBox(height: 24),
        _DutySection(
          title: 'COMPLETED',
          assignments: completed,
          provider: provider,
          dutyProvider: dutyProvider,
        ),
      ],
    );
  }
}

class _DutySection extends StatelessWidget {
  final String title;
  final List<DutyAssignment> assignments;
  final DutyAssignmentProvider provider;
  final DutyProvider dutyProvider;

  const _DutySection({
    required this.title,
    required this.assignments,
    required this.provider,
    required this.dutyProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (assignments.isEmpty)
          const Text('No duties here.')
        else
          ...assignments.map(
            (assignment) => _DutyCard(
              assignment: assignment,
              provider: provider,
              dutyProvider: dutyProvider,
            ),
          ),
      ],
    );
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({
    required this.assignment,
    required this.provider,
    required this.dutyProvider,
  });

  final DutyAssignment assignment;
  final DutyAssignmentProvider provider;
  final DutyProvider dutyProvider;

  @override
  Widget build(BuildContext context) {
    // Duty is only needed for the principal's edit shortcut now -- the
    // swap cutoff uses the assignment's own time snapshot.
    final duty = dutyProvider.dutyById(assignment.dutyId);
    final canSwap = DutyTimeUtils.canStillSwap(assignment.date, assignment.timeStart);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          assignment.status == DutyAssignmentStatus.completed
              ? Icons.check_circle
              : Icons.assignment_outlined,
          color: assignment.status == DutyAssignmentStatus.completed
              ? Colors.green
              : null,
        ),
        title: Text(
          assignment.dutyNameSnapshot,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(assignment.locationNameSnapshot),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(assignment.teacherNameSnapshots.join(', '))),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${assignment.timeStart} - ${assignment.timeEnd}'),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (canSwap)
              IconButton(
                tooltip: 'Swap',
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => DutySwapDialog(assignment: assignment),
                ),
              ),
            if (dutyProvider.isPrincipal && duty != null)
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => DutyEditorDialog(duty: duty),
                ),
              ),
            IconButton(
              tooltip: 'Details',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => DutyDetailSheet(assignment: assignment),
              ),
            ),
          ],
        ),
        children: [
          // Same fix as the detail sheet: go straight to the
          // assignment-scoped task stream instead of the teacher-scoped
          // cache, so this shows tasks for any assignment, not just the
          // current signed-in teacher's own.
          StreamBuilder<List<DutyTaskAssignment>>(
            stream: provider.watchTasksForAssignment(assignment.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tasks assigned.'),
                );
              }
              return Column(
                children: tasks.map((task) => _TaskTile(task: task)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final DutyTaskAssignment task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: task.isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(task.taskNameSnapshot),
      subtitle: Text(task.isCompleted ? 'Completed' : 'Pending'),
      trailing: task.photoUrl != null && task.photoUrl!.isNotEmpty
          ? const Icon(Icons.image)
          : null,
    );
  }
}