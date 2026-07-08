// Cretate Duty
// Edit Duty
// Select Location
// Create Locations
// Create Tasks
// Save/Delete

  void _showDutyEditor(BuildContext context, {Duty? duty}) {
    final provider = context.read<DutyProvider>();
    final title = TextEditingController(text: duty?.title ?? '');
    var startTime = _timeOfDayFromText(duty?.timeStart ?? '07:00');
    var endTime = _timeOfDayFromText(duty?.timeEnd ?? '08:00');
    final taskText = TextEditingController(
        text: duty?.tasks.map((task) => task.name).join('\n') ??
            'Inspect area\nSubmit photo proof');
    final newLocation = TextEditingController();
    var selectedDate = duty?.date ?? provider.selectedDate;
    var isAllDay = duty?.isAllDay ?? false;
    var minTeachers = duty?.minTeachersPerVenue ?? 1;
    var recurrence = duty?.recurrence ?? DutyRecurrence.once;
    var selectedLocations =
        duty?.locations.map((e) => e.id).toSet() ?? <String>{};

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text(duty == null ? 'Create duty' : 'Edit duty'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: title,
                      decoration:
                          const InputDecoration(labelText: 'Duty name')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 10)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 10)),
                              initialDate: selectedDate,
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.event_outlined),
                          label: Text(DateFormat.yMMMd().format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('All day'),
                        selected: isAllDay,
                        onSelected: (value) => setState(() => isAllDay = value),
                      ),
                    ],
                  ),
                  if (!isAllDay) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: startTime);
                              if (picked != null) {
                                setState(() => startTime = picked);
                              }
                            },
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text('Start ${startTime.format(context)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: endTime);
                              if (picked != null) {
                                setState(() => endTime = picked);
                              }
                            },
                            icon: const Icon(Icons.schedule),
                            label: Text('End ${endTime.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DutyRecurrence>(
                    initialValue: recurrence,
                    decoration: const InputDecoration(labelText: 'Routine'),
                    items: const [
                      DropdownMenuItem(
                          value: DutyRecurrence.once, child: Text('One time')),
                      DropdownMenuItem(
                          value: DutyRecurrence.daily, child: Text('Daily')),
                      DropdownMenuItem(
                          value: DutyRecurrence.weekly, child: Text('Weekly')),
                      DropdownMenuItem(
                          value: DutyRecurrence.monthly,
                          child: Text('Monthly')),
                    ],
                    onChanged: (value) => setState(
                        () => recurrence = value ?? DutyRecurrence.once),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Locations',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newLocation,
                          decoration: const InputDecoration(
                              labelText: 'Add new location'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Add location',
                        onPressed: () async {
                          final name = newLocation.text.trim();
                          if (name.isEmpty) return;
                          final added = await provider.addLocation(name);
                          if (added != null) {
                            setState(() {
                              selectedLocations.add(added.id);
                              newLocation.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_location_alt_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: provider.locations
                        .map((location) => FilterChip(
                              label: Text(location.name),
                              selected: selectedLocations.contains(location.id),
                              onSelected: (value) => setState(() {
                                value
                                    ? selectedLocations.add(location.id)
                                    : selectedLocations.remove(location.id);
                              }),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Text('Minimum teachers per venue')),
                      IconButton(
                          onPressed: minTeachers > 1
                              ? () => setState(() => minTeachers--)
                              : null,
                          icon: const Icon(Icons.remove)),
                      Text('$minTeachers'),
                      IconButton(
                          onPressed: () => setState(() => minTeachers++),
                          icon: const Icon(Icons.add)),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Teachers are auto-assigned from active teachers who are not on leave or in training.'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: taskText,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                        labelText: 'Task checklist, one per line'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (duty != null)
              TextButton(
                onPressed: () async {
                  await provider.deleteDuty(duty.id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Delete'),
              ),
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final locations = provider.locations
                    .where(
                        (location) => selectedLocations.contains(location.id))
                    .toList();
                final existingTasks = {
                  for (final task in duty?.tasks ?? const <DutyTask>[])
                    task.id: task
                };
                final tasks = taskText.text
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final id =
                      '${entry.key}_${entry.value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
                  return existingTasks[id]?.copyWith(name: entry.value) ??
                      DutyTask(id: id, name: entry.value);
                }).toList();
                final next = Duty(
                  id: duty?.id ?? '',
                  title: title.text.trim().isEmpty
                      ? 'Untitled duty'
                      : title.text.trim(),
                  date: selectedDate,
                  timeStart: isAllDay ? '00:00' : _formatTime(startTime),
                  timeEnd: isAllDay ? '23:59' : _formatTime(endTime),
                  isAllDay: isAllDay,
                  locations: locations,
                  teacherAssignments: duty?.teacherAssignments ?? const {},
                  teacherNames: duty?.teacherNames ?? const {},
                  tasks: tasks,
                  thumbnailUrl: duty?.thumbnailUrl,
                  minTeachersPerVenue: minTeachers,
                  recurrence: recurrence,
                );
                duty == null
                    ? await provider.createDuty(next)
                    : await provider.updateDuty(next);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
