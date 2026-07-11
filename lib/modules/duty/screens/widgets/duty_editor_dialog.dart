import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/duty.dart';
import '../../models/duty_task.dart';
import '../../providers/duty_provider.dart';
import '../../providers/duty_location_provider.dart';
import '../../utils/duty_confirm.dart';
import '../../utils/duty_time_utils.dart';

/// Create/edit dialog for a *duty definition* (title, schedule window,
/// recurrence, locations, minimum teachers, task checklist). This replaces
/// the old `_showDutyEditor` which used to also carry date/teacher-
/// assignment fields that now belong to `DutyAssignment` instead.
class DutyEditorDialog extends StatefulWidget {
  const DutyEditorDialog({super.key, this.duty});

  final Duty? duty;

  @override
  State<DutyEditorDialog> createState() => _DutyEditorDialogState();
}

class _DutyEditorDialogState extends State<DutyEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _taskText;
  final _newLocation = TextEditingController();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isAllDay;
  late int _minTeachers;
  late DutyRecurrence _recurrence;
  int? _recurrenceDayOfWeek;
  int? _recurrenceDayOfMonth;
  late Set<String> _selectedLocations;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final duty = widget.duty;

    _title = TextEditingController(text: duty?.title ?? '');
    _startTime = _timeFromText(duty?.timeStart ?? '07:00');
    _endTime = _timeFromText(duty?.timeEnd ?? '08:00');
    _isAllDay = duty?.isAllDay ?? false;
    _minTeachers = duty?.minTeachersPerVenue ?? 1;
    _recurrence = duty?.recurrence ?? DutyRecurrence.once;
    _recurrenceDayOfWeek = duty?.recurrenceDayOfWeek ?? DateTime.monday;
    _recurrenceDayOfMonth = duty?.recurrenceDayOfMonth ?? 1;
    _selectedLocations = duty?.locations.map((l) => l.id).toSet() ?? <String>{};

    final existingTasks =
        duty == null ? <DutyTask>[] : context.read<DutyProvider>().tasksForDuty(duty.id);
    _taskText = TextEditingController(
      text: existingTasks.isEmpty
          ? 'Inspect area\nSubmit photo proof'
          : existingTasks.map((t) => t.title).join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dutyProvider = context.watch<DutyProvider>();
    final locationProvider = context.watch<DutyLocationProvider>();
    final duty = widget.duty;

    return AlertDialog(
      title: Text(duty == null ? 'Create duty' : 'Edit duty'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Duty name'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text('Start ${_startTime.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('All day'),
                    selected: _isAllDay,
                    onSelected: (v) => setState(() => _isAllDay = v),
                  ),
                ],
              ),
              if (!_isAllDay) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked =
                        await showTimePicker(context: context, initialTime: _endTime);
                    if (picked != null) setState(() => _endTime = picked);
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text('End ${_endTime.format(context)}'),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<DutyRecurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(labelText: 'Routine'),
                items: const [
                  DropdownMenuItem(
                      value: DutyRecurrence.once, child: Text('One time')),
                  DropdownMenuItem(
                      value: DutyRecurrence.daily, child: Text('Daily')),
                  DropdownMenuItem(
                      value: DutyRecurrence.weekly, child: Text('Weekly')),
                  DropdownMenuItem(
                      value: DutyRecurrence.monthly, child: Text('Monthly')),
                ],
                onChanged: (v) =>
                    setState(() => _recurrence = v ?? DutyRecurrence.once),
              ),
              if (_recurrence == DutyRecurrence.weekly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _recurrenceDayOfWeek,
                  decoration: const InputDecoration(labelText: 'Which day (weekly)'),
                  items: List.generate(7, (i) => i + 1)
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(DutyTimeUtils.weekdayName(day)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _recurrenceDayOfWeek = v),
                ),
              ],
              if (_recurrence == DutyRecurrence.monthly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _recurrenceDayOfMonth,
                  decoration: const InputDecoration(labelText: 'Which day (monthly)'),
                  items: List.generate(31, (i) => i + 1)
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(DutyTimeUtils.ordinal(day)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _recurrenceDayOfMonth = v),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Locations', style: Theme.of(context).textTheme.titleSmall),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newLocation,
                      decoration:
                          const InputDecoration(labelText: 'Add new location'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Add location',
                    onPressed: () async {
                      final name = _newLocation.text.trim();
                      if (name.isEmpty) return;
                      await context.read<DutyLocationProvider>().addLocation(name: name);
                      _newLocation.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.add_location_alt_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: locationProvider.activeLocations
                    .map((location) => FilterChip(
                          label: Text(location.name),
                          selected: _selectedLocations.contains(location.id),
                          onSelected: (v) => setState(() {
                            v
                                ? _selectedLocations.add(location.id)
                                : _selectedLocations.remove(location.id);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('Minimum teachers per venue')),
                  IconButton(
                    onPressed: _minTeachers > 1
                        ? () => setState(() => _minTeachers--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_minTeachers'),
                  IconButton(
                    onPressed: () => setState(() => _minTeachers++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Teachers are auto-assigned from active teachers who are '
                  'not on leave.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskText,
                minLines: 3,
                maxLines: 6,
                decoration:
                    const InputDecoration(labelText: 'Task checklist, one per line'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (duty != null)
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    final confirmed = await showDutyConfirmDialog(
                      context,
                      title: 'Delete this duty?',
                      message:
                          "This removes the duty definition and every upcoming "
                          "assignment generated from it that hasn't happened yet. "
                          "This can't be undone.",
                      confirmLabel: 'Delete',
                      danger: true,
                    );
                    if (!confirmed) return;
                    if (!context.mounted) return;

                    setState(() => _saving = true);
                    await dutyProvider.deleteDuty(duty.id);
                    if (!context.mounted) return;
                    if (dutyProvider.error != null) {
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(dutyProvider.error!)),
                      );
                      return;
                    }
                    Navigator.pop(context);
                  },
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(context, dutyProvider, locationProvider),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save(
    BuildContext context,
    DutyProvider dutyProvider,
    DutyLocationProvider locationProvider,
  ) async {
    if (widget.duty != null) {
      final confirmed = await showDutyConfirmDialog(
        context,
        title: 'Save changes?',
        message:
            "This updates the duty's own definition, and refreshes every "
            "upcoming assignment generated from it (name, time, and task "
            "wording) that hasn't happened yet. Assignments that have "
            "already happened are left as-is.",
        confirmLabel: 'Save',
      );
      if (!confirmed) return;
    }

    if (!context.mounted) return;

    final locations = locationProvider.locations
        .where((l) => _selectedLocations.contains(l.id))
        .toList();

    // Match new checklist lines back to existing tasks BY POSITION, not by
    // title. Matching by title used to mean editing a task's wording
    // deleted the old task and created a brand-new one with a new id --
    // which orphaned any `DutyTaskAssignment` docs still pointing at the
    // old id (their snapshot never got refreshed) and left the new task
    // with no assignment-level presence at all. Position-based matching
    // keeps the same task id across a title edit, so it updates in place
    // instead. Trade-off: reordering lines (not just editing them) will be
    // read as renames rather than a reorder, since there's no per-line id
    // exposed in this plain-text editor.
    final existingTasks =
        widget.duty == null ? <DutyTask>[] : dutyProvider.tasksForDuty(widget.duty!.id);

    final newTitles = _taskText.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final tasks = <DutyTask>[
      for (var i = 0; i < newTitles.length; i++)
        DutyTask(
          id: i < existingTasks.length ? existingTasks[i].id : '',
          dutyId: widget.duty?.id ?? '',
          dutyNameSnapshot: _title.text.trim(),
          title: newTitles[i],
        ),
    ];

    final duty = Duty(
      id: widget.duty?.id ?? '',
      title: _title.text.trim().isEmpty ? 'Untitled duty' : _title.text.trim(),
      timeStart: _isAllDay ? '00:00' : _formatTime(_startTime),
      timeEnd: _isAllDay ? '23:59' : _formatTime(_endTime),
      isAllDay: _isAllDay,
      recurrence: _recurrence,
      recurrenceDayOfWeek: _recurrence == DutyRecurrence.weekly ? _recurrenceDayOfWeek : null,
      recurrenceDayOfMonth: _recurrence == DutyRecurrence.monthly ? _recurrenceDayOfMonth : null,
      locations: locations,
      minTeachersPerVenue: _minTeachers,
    );

    setState(() => _saving = true);
    if (widget.duty == null) {
      await dutyProvider.createDuty(duty, tasks);
    } else {
      await dutyProvider.updateDuty(duty, tasks);
    }

    if (!context.mounted) return;
    if (dutyProvider.error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dutyProvider.error!)),
      );
      return;
    }
    Navigator.pop(context);
  }
}

TimeOfDay _timeFromText(String value) {
  final parts = value.split(':').map((p) => int.tryParse(p) ?? 0).toList();
  return TimeOfDay(
    hour: parts.isEmpty ? 0 : parts[0],
    minute: parts.length > 1 ? parts[1] : 0,
  );
}

String _formatTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';