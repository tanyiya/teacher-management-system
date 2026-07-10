import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/duty.dart';
import '../models/duty_assignment.dart';
import '../models/duty_swap.dart';
import '../models/duty_task_assignment.dart';
import '../providers/duty_assignment_provider.dart';
import '../providers/duty_provider.dart';
import '../providers/duty_schedule_provider.dart';
import '../providers/duty_swap_provider.dart';
import '../utils/duty_time_utils.dart';
import 'widgets/duty_detail_sheet.dart';
import 'widgets/duty_editor_dialog.dart';
import 'widgets/duty_swap_dialog.dart';
import 'widgets/duty_swap_requests_section.dart';

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
        .toList()
      ..sort((a, b) =>
          DutyTimeUtils.toMinutes(a.timeStart).compareTo(DutyTimeUtils.toMinutes(b.timeStart)));

    final completed = visible
        .where((a) => a.status == DutyAssignmentStatus.completed)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DutySwapRequestsSection(teacherId: dutyProvider.currentUserId),
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
    // Duty is needed for the principal's edit shortcut, and now also for
    // the recurrence label (which day, for weekly/monthly duties).
    final duty = dutyProvider.dutyById(assignment.dutyId);
    final ownsThisDuty = assignment.teacherIds.contains(dutyProvider.currentUserId);
    final canSwap = (dutyProvider.isPrincipal || ownsThisDuty) &&
        DutyTimeUtils.canStillSwap(assignment.date, assignment.timeStart);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.only(left: 12, right: 4),
        childrenPadding: EdgeInsets.zero,
        title: Text(
          assignment.dutyNameSnapshot,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaRow(icon: Icons.place_outlined, text: assignment.locationNameSnapshot),
              const SizedBox(height: 1),
              _MetaRow(
                icon: Icons.person_outline,
                text: assignment.teacherNameSnapshots.join(', '),
              ),
              const SizedBox(height: 1),
              _MetaRow(
                icon: Icons.schedule_outlined,
                text: _timeLabel(duty, assignment),
              ),
              Builder(builder: (context) {
                final pending = context
                    .watch<DutySwapProvider>()
                    .swapsForAssignment(assignment.id)
                    .where((s) => s.status == DutySwapStatus.pending)
                    .toList();
                if (pending.isEmpty) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: _MetaRow(
                    icon: Icons.swap_horiz,
                    text: 'Swap pending approval',
                    color: Colors.orange,
                  ),
                );
              }),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canSwap)
              _CompactIconButton(
                icon: Icons.swap_horiz,
                tooltip: 'Swap',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => DutySwapDialog(assignment: assignment),
                ),
              ),
            if (dutyProvider.isPrincipal && duty != null)
              _CompactIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => DutyEditorDialog(duty: duty),
                ),
              ),
            _CompactIconButton(
              icon: Icons.chevron_right,
              tooltip: 'Details',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => DutyDetailSheet(assignment: assignment),
              ),
            ),
          ],
        ),
        children: [
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

  String _timeLabel(Duty? duty, DutyAssignment assignment) {
    final base = '${assignment.timeStart} - ${assignment.timeEnd}';
    if (duty == null) return base;
    switch (duty.recurrence) {
      case DutyRecurrence.weekly:
      case DutyRecurrence.monthly:
        return '${duty.recurrenceLabel} • $base';
      case DutyRecurrence.daily:
      case DutyRecurrence.once:
        return base;
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: color ?? Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      splashRadius: 18,
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final DutyTaskAssignment task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
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