import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/duty_assignment.dart';
import '../models/duty_task_assignment.dart';
import '../providers/duty_assignment_provider.dart';
import '../providers/duty_provider.dart';
import '../utils/duty_time_utils.dart';
import '../widgets/duty_detail_sheet.dart';
import '../widgets/duty_editor_dialog.dart';
import '../widgets/duty_swap_dialog.dart';

class DutyListScreen extends StatefulWidget {
  const DutyListScreen({super.key});

  @override
  State<DutyListScreen> createState() => _DutyListScreenState();
}

class _DutyListScreenState extends State<DutyListScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyAssignmentProvider>();
    final dutyProvider = context.watch<DutyProvider>();

    return Column(
      children: [
        _DateSelector(
          date: selectedDate,
          onChanged: (date) {
            setState(() => selectedDate = date);
            context.read<DutyAssignmentProvider>().setDate(date);
          },
        ),
        if (provider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (provider.error != null)
          Expanded(child: Center(child: Text(provider.error!)))
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DutySection(
                  title: 'TODO',
                  assignments: provider.todoAssignments,
                  provider: provider,
                  dutyProvider: dutyProvider,
                ),
                const SizedBox(height: 24),
                _DutySection(
                  title: 'COMPLETED',
                  assignments: provider.completedAssignments,
                  provider: provider,
                  dutyProvider: dutyProvider,
                ),
              ],
            ),
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
    final tasks = provider.tasksForAssignment(assignment.id);
    // Duty is only needed for the principal's edit shortcut now -- the
    // swap cutoff uses the assignment's own time snapshot.
    final duty = dutyProvider.dutyById(assignment.dutyId);
    final canSwap = DutyTimeUtils.canStillSwap(assignment.date, assignment.timeStart);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          assignment.status.name == 'completed'
              ? Icons.check_circle
              : Icons.assignment_outlined,
          color:
              assignment.status.name == 'completed' ? Colors.green : null,
        ),
        title: Text(
          assignment.dutyNameSnapshot,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(assignment.locationNameSnapshots.join(', ')),
            Text(assignment.teacherNameSnapshots.join(', ')),
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
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No tasks assigned.'),
            )
          else
            ...tasks.map((task) => _TaskTile(task: task)),
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

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final Function(DateTime) onChanged;

  const _DateSelector({required this.date, required this.onChanged});

  Future<void> _pickDate(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _pickDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month),
              const SizedBox(width: 12),
              Text('${date.day}/${date.month}/${date.year}'),
              const Spacer(),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}