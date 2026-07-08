// TODO duties
// Completed duties
// Quick Actions
import 'package:flutter/material.dart';

class DutyScheduleScreen extends StatefulWidget {
  const DutyScheduleScreen({super.key});

  @override
  State<DutyScheduleScreen> createState() => _DutyScheduleScreenState();
}

class _DutyScheduleScreenState extends State<DutyScheduleScreen> {


  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStateProvider>().currentUser;
    final provider = context.watch<DutyProvider>();
    if (provider.currentTeacherId != user?.id ||
        provider.currentTeacherName != user?.fullName ||
        provider.userRole != _roleFromUser(user)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DutyProvider>().setUser(
              teacherId: user?.id,
              teacherName: user?.fullName,
              role: user?.role ?? 'teacher',
            );
      });
    }

    return 
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.viewMode == DutyViewMode.calendar
                    ? _CalendarGrid(
                        onOpen: _showDutyDetail, onEdit: _showDutyEditor)
                    : _DutyList(
                        onOpen: _showDutyDetail,
                        onEdit: _showDutyEditor,
                        onComplete: _completeTask,
                        onSwap: _showSwapDialog),
          ),


}



class _DutyList extends StatelessWidget {
  const _DutyList(
      {required this.onOpen,
      required this.onEdit,
      required this.onComplete,
      required this.onSwap});

  final void Function(BuildContext context, Duty duty) onOpen;
  final void Function(BuildContext context, {Duty? duty}) onEdit;
  final Future<void> Function(BuildContext context, Duty duty, DutyTask task)
      onComplete;
  final void Function(BuildContext context, Duty duty) onSwap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DutyListSection(
            title: 'TODO',
            duties: provider.todoDuties,
            onOpen: onOpen,
            onEdit: onEdit,
            onComplete: onComplete,
            onSwap: onSwap),
        const SizedBox(height: 16),
        _DutyListSection(
            title: 'COMPLETED',
            duties: provider.completedDuties,
            onOpen: onOpen,
            onEdit: onEdit,
            onComplete: onComplete,
            onSwap: onSwap),
      ],
    );
  }
}

class _DutyListSection extends StatelessWidget {
  const _DutyListSection(
      {required this.title,
      required this.duties,
      required this.onOpen,
      required this.onEdit,
      required this.onComplete,
      required this.onSwap});

  final String title;
  final List<Duty> duties;
  final void Function(BuildContext context, Duty duty) onOpen;
  final void Function(BuildContext context, {Duty? duty}) onEdit;
  final Future<void> Function(BuildContext context, Duty duty, DutyTask task)
      onComplete;
  final void Function(BuildContext context, Duty duty) onSwap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (duties.isEmpty) const Text('No duties here.'),
        ...duties.map((duty) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                leading: duty.thumbnailUrl == null
                    ? const Icon(Icons.assignment_outlined)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(duty.thumbnailUrl!,
                            width: 44, height: 44, fit: BoxFit.cover)),
                title: Text(duty.title),
                subtitle: Text(
                    '${duty.timeStart} - ${duty.timeEnd}  •  ${duty.locations.map((e) => e.name).join(', ')}\n${duty.teacherIds.map((id) => duty.teacherNames[id] ?? id).join(', ')}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (provider.canRequestSwap(duty))
                      IconButton(
                          tooltip: 'Swap',
                          onPressed: () => onSwap(context, duty),
                          icon: const Icon(Icons.swap_horiz)),
                    if (provider.isPrincipal)
                      IconButton(
                          tooltip: 'Edit',
                          onPressed: () => onEdit(context, duty: duty),
                          icon: const Icon(Icons.edit_outlined)),
                    IconButton(
                        tooltip: 'Details',
                        onPressed: () => onOpen(context, duty),
                        icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                children: duty.tasks
                    .map((task) => ListTile(
                          title: Text(task.name),
                          subtitle: Text(task.isCompleted
                              ? 'Completed'
                              : 'Needs camera proof'),
                          leading: Icon(task.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked),
                          trailing: !task.isCompleted &&
                                  provider.canCompleteTask(duty)
                              ? IconButton(
                                  tooltip: 'Capture proof',
                                  onPressed: () =>
                                      onComplete(context, duty, task),
                                  icon: const Icon(Icons.photo_camera_outlined))
                              : null,
                        ))
                    .toList(),
              ),
            )),
      ],
    );
  }
}
