import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state_provider.dart';
import '../../teachers/models/teacher.dart';
import '../models/duty.dart';
import '../providers/ori_duty_provider.dart';

extension _TimeX on String {
  int toMinutes() {
    final parts = split(':').map((part) => int.tryParse(part) ?? 0).toList();
    return parts.first * 60 + (parts.length > 1 ? parts[1] : 0);
  }
}

class DutyScheduleScreen extends StatefulWidget {
  const DutyScheduleScreen({super.key});

  @override
  State<DutyScheduleScreen> createState() => _DutyScheduleScreenState();
}

class _DutyScheduleScreenState extends State<DutyScheduleScreen> {
  static const double _hourHeight = 72;
  static const double _timeWidth = 64;
  static const double _columnWidth = 220;
  static const int _startHour = 6;
  static const int _hourCount = 14;

  final _picker = ImagePicker();

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

    return Scaffold(
      backgroundColor: const Color(0xfff7f8fb),
      appBar: AppBar(
        title: const Text('Duty Management'),
        actions: [
          IconButton(
            tooltip: provider.viewMode == DutyViewMode.calendar
                ? 'List view'
                : 'Calendar view',
            onPressed: provider.toggleViewMode,
            icon: Icon(provider.viewMode == DutyViewMode.calendar
                ? Icons.view_agenda_outlined
                : Icons.calendar_month),
          ),
          if (provider.isPrincipal)
            IconButton(
              tooltip: 'Filters',
              onPressed: () => _showFilters(context, provider),
              icon: const Icon(Icons.filter_list),
            ),
        ],
      ),
      floatingActionButton: provider.isPrincipal
          ? FloatingActionButton(
              onPressed: () => _showDutyEditor(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          _TopBar(
              onAddLocation: provider.isPrincipal &&
                      provider.groupingMode == DutyGroupingMode.location
                  ? () => _showAddLocation(context)
                  : null),
          if (provider.error != null)
            MaterialBanner(
              content: Text(provider.error!),
              actions: [
                TextButton(
                    onPressed:
                        ScaffoldMessenger.of(context).hideCurrentMaterialBanner,
                    child: const Text('Dismiss')),
              ],
            ),
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
        ],
      ),
    );
  }

  Future<void> _completeTask(
      BuildContext context, Duty duty, DutyTask task) async {
    final provider = context.read<DutyProvider>();
    final image = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 78, maxWidth: 1600);
    if (image == null) return;
    await provider.completeTask(
      duty: duty,
      taskId: task.id,
      imageBytes: await image.readAsBytes(),
      fileName: image.name,
    );
  }

  void _showDutyDetail(BuildContext context, Duty duty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final provider = sheetContext.watch<DutyProvider>();
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
                      child: Text(duty.title,
                          style: Theme.of(context).textTheme.headlineSmall)),
                  if (provider.isPrincipal)
                    IconButton(
                      tooltip: 'Edit duty',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showDutyEditor(context, duty: duty);
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
              Text(
                  '${DateFormat.yMMMd().format(duty.date)}  ${duty.timeStart} - ${duty.timeEnd}'),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Locations and teachers',
                children: duty.locations
                    .map((location) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(location.name),
                          subtitle:
                              Text(duty.teacherLabelForLocation(location.id)),
                        ))
                    .toList(),
              ),
              _InfoSection(
                title: 'Tasks',
                children: duty.tasks
                    .map((task) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: task.photoUrl == null
                              ? Icon(task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(task.photoUrl!,
                                      width: 44, height: 44, fit: BoxFit.cover),
                                ),
                          title: Text(task.name),
                          subtitle: Text(task.isCompleted
                              ? 'Completed ${task.completedAt == null ? '' : DateFormat.jm().format(task.completedAt!)}'
                              : 'Pending proof photo'),
                          trailing: !task.isCompleted &&
                                  provider.canCompleteTask(duty)
                              ? IconButton(
                                  tooltip: 'Capture proof',
                                  onPressed: () =>
                                      _completeTask(context, duty, task),
                                  icon: const Icon(Icons.photo_camera_outlined),
                                )
                              : null,
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilters(BuildContext context, DutyProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: provider.teacherFilterId,
              decoration: const InputDecoration(labelText: 'Teacher'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All teachers')),
                ...provider.teachers.map((teacher) => DropdownMenuItem(
                    value: teacher.id, child: Text(teacher.fullName))),
              ],
              onChanged: provider.setTeacherFilter,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: provider.locationFilterId,
              decoration: const InputDecoration(labelText: 'Venue'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All venues')),
                ...provider.locations.map((location) => DropdownMenuItem(
                    value: location.id, child: Text(location.name))),
              ],
              onChanged: provider.setLocationFilter,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLocation(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add location'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Location name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await context.read<DutyProvider>().addLocation(controller.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSwapDialog(BuildContext context, Duty duty) async {
    final provider = context.read<DutyProvider>();
    final ids = await provider.eligibleSwapTeacherIds(duty);
    if (!context.mounted) return;
    String? fromTeacherId =
        duty.teacherIds.isNotEmpty ? duty.teacherIds.first : null;
    String? selectedId = ids.isNotEmpty ? ids.first : null;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Request swap'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${duty.title}\n${duty.timeStart} - ${duty.timeEnd}\n${duty.locations.map((e) => e.name).join(', ')}'),
              const SizedBox(height: 16),
              if (provider.isPrincipal)
                DropdownButtonFormField<String>(
                  initialValue: fromTeacherId,
                  decoration:
                      const InputDecoration(labelText: 'Replace teacher'),
                  items: duty.teacherIds
                      .map((id) => DropdownMenuItem(
                          value: id, child: Text(duty.teacherNames[id] ?? id)))
                      .toList(),
                  onChanged: (value) => setState(() => fromTeacherId = value),
                ),
              if (provider.isPrincipal) const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration:
                    const InputDecoration(labelText: 'Eligible teacher'),
                items: ids
                    .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text(provider.teachers
                              .firstWhere((t) => t.id == id,
                                  orElse: () => _fallbackTeacher(id))
                              .fullName),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: selectedId == null
                  ? null
                  : () async {
                      await provider.requestSwap(duty, selectedId!,
                          fromTeacherId: fromTeacherId);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
              child: Text(provider.isPrincipal ? 'Swap now' : 'Request'),
            ),
          ],
        ),
      ),
    );
  }

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

class _TopBar extends StatelessWidget {
  const _TopBar({this.onAddLocation});

  final VoidCallback? onAddLocation;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    final date = provider.selectedDate;
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous day',
              onPressed: () => provider
                  .setSelectedDate(date.subtract(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 10)),
                  lastDate: DateTime.now().add(const Duration(days: 10)),
                  initialDate: date,
                );
                if (picked != null) provider.setSelectedDate(picked);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(DateFormat('EEE, d MMM').format(date)),
            ),
            IconButton(
              tooltip: 'Next day',
              onPressed: () =>
                  provider.setSelectedDate(date.add(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_right),
            ),
            SegmentedButton<DutyGroupingMode>(
              segments: const [
                ButtonSegment(
                    value: DutyGroupingMode.location,
                    label: Text('Locations'),
                    icon: Icon(Icons.place_outlined)),
                ButtonSegment(
                    value: DutyGroupingMode.teacher,
                    label: Text('Teachers'),
                    icon: Icon(Icons.people_outline)),
              ],
              selected: {provider.groupingMode},
              onSelectionChanged: (value) =>
                  provider.setGroupingMode(value.first),
            ),
            if (onAddLocation != null)
              IconButton.filledTonal(
                tooltip: 'Add location',
                onPressed: onAddLocation,
                icon: const Icon(Icons.add_location_alt_outlined),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatefulWidget {
  const _CalendarGrid({required this.onOpen, required this.onEdit});

  final void Function(BuildContext context, Duty duty) onOpen;
  final void Function(BuildContext context, {Duty? duty}) onEdit;

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  final _horizontalHeader = ScrollController();
  final _horizontalBody = ScrollController();
  final _verticalTime = ScrollController();
  final _verticalBody = ScrollController();
  bool _syncingHorizontal = false;
  bool _syncingVertical = false;

  @override
  void initState() {
    super.initState();
    _horizontalHeader
        .addListener(() => _syncHorizontal(_horizontalHeader, _horizontalBody));
    _horizontalBody
        .addListener(() => _syncHorizontal(_horizontalBody, _horizontalHeader));
    _verticalTime
        .addListener(() => _syncVertical(_verticalTime, _verticalBody));
    _verticalBody
        .addListener(() => _syncVertical(_verticalBody, _verticalTime));
  }

  void _syncHorizontal(ScrollController source, ScrollController target) {
    if (_syncingHorizontal || !source.hasClients || !target.hasClients) return;
    _syncingHorizontal = true;
    target.jumpTo(source.offset.clamp(0, target.position.maxScrollExtent));
    _syncingHorizontal = false;
  }

  void _syncVertical(ScrollController source, ScrollController target) {
    if (_syncingVertical || !source.hasClients || !target.hasClients) return;
    _syncingVertical = true;
    target.jumpTo(source.offset.clamp(0, target.position.maxScrollExtent));
    _syncingVertical = false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    final columns = provider.groupingMode == DutyGroupingMode.location
        ? provider.locations
            .map((location) => _ColumnMeta(location.id, location.name))
            .toList()
        : provider.teachers
            .map((teacher) => _ColumnMeta(teacher.id, teacher.fullName))
            .toList();
    if (columns.isEmpty) {
      return const Center(
          child: Text('No locations or teachers available yet.'));
    }

    final contentWidth = columns.length * _DutyScheduleScreenState._columnWidth;
    const contentHeight = _DutyScheduleScreenState._hourCount *
        _DutyScheduleScreenState._hourHeight;

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Container(
                width: _DutyScheduleScreenState._timeWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffe5e7eb)),
                    color: Colors.white),
                child: const Icon(Icons.schedule_outlined, size: 18),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalHeader,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: columns
                        .map((column) => Container(
                              width: _DutyScheduleScreenState._columnWidth,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xffe5e7eb)),
                                  color: Colors.white),
                              child: Text(column.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: _DutyScheduleScreenState._timeWidth,
                child: SingleChildScrollView(
                  controller: _verticalTime,
                  child: const _TimeColumn(height: contentHeight),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalBody,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _verticalBody,
                    child: SizedBox(
                      width: contentWidth,
                      height: contentHeight,
                      child: Stack(
                        children: [
                          _CalendarBodyBackground(columns: columns),
                          ...provider.duties.expand((duty) =>
                              _blocksForDuty(context, provider, duty, columns)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Iterable<Widget> _blocksForDuty(BuildContext context, DutyProvider provider,
      Duty duty, List<_ColumnMeta> columns) {
    final ids = provider.groupingMode == DutyGroupingMode.location
        ? duty.locations.map((e) => e.id)
        : duty.teacherIds;
    return ids.map((id) {
      final index = columns.indexWhere((column) => column.id == id);
      if (index < 0) return const SizedBox.shrink();
      final top = (duty.timeStart.toMinutes() -
              _DutyScheduleScreenState._startHour * 60) *
          (_DutyScheduleScreenState._hourHeight / 60);
      final height = ((duty.timeEnd.toMinutes() - duty.timeStart.toMinutes()) *
              (_DutyScheduleScreenState._hourHeight / 60))
          .clamp(40, 240)
          .toDouble();
      final color = provider.groupingMode == DutyGroupingMode.location
          ? provider.colorForTeacher(
              duty.teacherIds.isEmpty ? duty.id : duty.teacherIds.first)
          : provider.colorForLocation(
              duty.locations.isEmpty ? duty.id : duty.locations.first.id);
      return Positioned(
        top: top.clamp(0, double.infinity).toDouble(),
        left: index * _DutyScheduleScreenState._columnWidth + 8,
        width: _DutyScheduleScreenState._columnWidth - 16,
        height: height,
        child: InkWell(
          onTap: () => widget.onOpen(context, duty),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final compact = constraints.maxHeight < 64;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(duty.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12))),
                        if (provider.isPrincipal)
                          InkWell(
                            onTap: () => widget.onEdit(context, duty: duty),
                            child: const Icon(Icons.edit_outlined,
                                color: Colors.white, size: 16),
                          ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Flexible(
                          child: Text(
                              duty.teacherIds
                                  .map((id) => duty.teacherNames[id] ?? id)
                                  .join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11))),
                      Flexible(
                          child: Text(
                              duty.locations.map((e) => e.name).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11))),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _horizontalHeader.dispose();
    _horizontalBody.dispose();
    _verticalTime.dispose();
    _verticalBody.dispose();
    super.dispose();
  }
}

class _CalendarBodyBackground extends StatelessWidget {
  const _CalendarBodyBackground({required this.columns});

  final List<_ColumnMeta> columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_DutyScheduleScreenState._hourCount, (index) {
          return Row(
            children: [
              ...columns.map((_) => Container(
                    width: _DutyScheduleScreenState._columnWidth,
                    height: _DutyScheduleScreenState._hourHeight,
                    decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffe5e7eb)),
                        color: Colors.white),
                  )),
            ],
          );
        }),
      ],
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        children: List.generate(_DutyScheduleScreenState._hourCount, (index) {
          final hour = _DutyScheduleScreenState._startHour + index;
          return Container(
            width: _DutyScheduleScreenState._timeWidth,
            height: _DutyScheduleScreenState._hourHeight,
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffe5e7eb)),
                color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child:
                  Text(_formatHour(hour), style: const TextStyle(fontSize: 11)),
            ),
          );
        }),
      ),
    );
  }
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

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ColumnMeta {
  final String id;
  final String label;

  const _ColumnMeta(this.id, this.label);
}

TeacherRecord _fallbackTeacher(String id) {
  return TeacherRecord(
    id: id,
    username: id,
    email: '',
    fullName: id,
    role: 'teacher',
    icNumber: '',
    gender: '',
    dob: '',
    address: '',
    phoneNumber: '',
    maritalStatus: '',
    emergencyContactName: '',
    emergencyContactNumber: '',
    currentScore: 0,
    yearlyKpi: 0,
    status: 'active',
    documents: const {},
  );
}

DutyUserRole _roleFromUser(TeacherRecord? user) {
  final role = user?.role.toLowerCase() ?? 'teacher';
  return role == 'principal' || role == 'admin'
      ? DutyUserRole.principal
      : DutyUserRole.teacher;
}

TimeOfDay _timeOfDayFromText(String value) {
  final parts =
      value.split(':').map((part) => int.tryParse(part) ?? 0).toList();
  return TimeOfDay(
      hour: parts.isEmpty ? 0 : parts[0],
      minute: parts.length > 1 ? parts[1] : 0);
}

String _formatTime(TimeOfDay value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _formatHour(int hour) {
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour $suffix';
}
