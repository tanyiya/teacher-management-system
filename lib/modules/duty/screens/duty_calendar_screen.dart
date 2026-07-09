import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/duty_assignment.dart';
import '../providers/duty_assignment_provider.dart';
import '../providers/duty_provider.dart';
import '../providers/duty_location_provider.dart';
import '../providers/duty_schedule_provider.dart';
import '../utils/duty_time_utils.dart';
import '../widgets/duty_detail_sheet.dart';
import '../widgets/duty_editor_dialog.dart';

/// Grid rebuild of the old `_CalendarGrid`. The key schema difference:
/// `DutyAssignment` no longer carries its own time range, so block position
/// is computed by looking up the parent `Duty` (via [DutyProvider]) for its
/// `timeStart`/`timeEnd`.
class DutyCalendarScreen extends StatefulWidget {
  const DutyCalendarScreen({super.key});

  @override
  State<DutyCalendarScreen> createState() => _DutyCalendarScreenState();
}

class _DutyCalendarScreenState extends State<DutyCalendarScreen> {
  static const double hourHeight = 72;
  static const double timeWidth = 64;
  static const double columnWidth = 220;
  static const int startHour = 6;
  static const int hourCount = 14;

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
    final assignmentProvider = context.watch<DutyAssignmentProvider>();
    final dutyProvider = context.watch<DutyProvider>();
    final locationProvider = context.watch<DutyLocationProvider>();
    final schedule = context.watch<DutyScheduleProvider>();

    if (assignmentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final columns = schedule.groupingMode == DutyGroupingMode.location
        ? locationProvider.activeLocations
            .map((l) => _ColumnMeta(l.id, l.name))
            .toList()
        : dutyProvider.activeTeachers
            .map((t) => _ColumnMeta(t.id, t.fullName))
            .toList();

    if (columns.isEmpty) {
      return const Center(
        child: Text('No locations or teachers available yet.'),
      );
    }

    var assignments = assignmentProvider.visibleAssignments;
    if (schedule.teacherFilterId != null) {
      assignments = assignments
          .where((a) => a.teacherIds.contains(schedule.teacherFilterId))
          .toList();
    }
    if (schedule.locationFilterId != null) {
      assignments = assignments
          .where((a) => a.locationIds.contains(schedule.locationFilterId))
          .toList();
    }

    final contentWidth = columns.length * columnWidth;
    const contentHeight = hourCount * hourHeight;

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Container(
                width: timeWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffe5e7eb)),
                  color: Colors.white,
                ),
                child: const Icon(Icons.schedule_outlined, size: 18),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalHeader,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: columns
                        .map((c) => Container(
                              width: columnWidth,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: const Color(0xffe5e7eb)),
                                color: Colors.white,
                              ),
                              child: Text(
                                c.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
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
                width: timeWidth,
                child: SingleChildScrollView(
                  controller: _verticalTime,
                  child: SizedBox(
                    height: contentHeight,
                    child: Column(
                      children: List.generate(hourCount, (index) {
                        final hour = startHour + index;
                        return Container(
                          width: timeWidth,
                          height: hourHeight,
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xffe5e7eb)),
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_formatHour(hour),
                                style: const TextStyle(fontSize: 11)),
                          ),
                        );
                      }),
                    ),
                  ),
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
                          _backgroundGrid(columns),
                          ...assignments.expand(
                            (a) => _blocksForAssignment(
                              context,
                              a,
                              columns,
                              dutyProvider,
                              schedule,
                            ),
                          ),
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

  Widget _backgroundGrid(List<_ColumnMeta> columns) {
    return Column(
      children: List.generate(hourCount, (_) {
        return Row(
          children: columns
              .map((_) => Container(
                    width: columnWidth,
                    height: hourHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffe5e7eb)),
                      color: Colors.white,
                    ),
                  ))
              .toList(),
        );
      }),
    );
  }

  Iterable<Widget> _blocksForAssignment(
    BuildContext context,
    DutyAssignment assignment,
    List<_ColumnMeta> columns,
    DutyProvider dutyProvider,
    DutyScheduleProvider schedule,
  ) sync* {
    // Duty is only needed here for the principal's edit shortcut -- timing
    // now comes straight off the assignment's own snapshot.
    final duty = dutyProvider.dutyById(assignment.dutyId);

    final ids = schedule.groupingMode == DutyGroupingMode.location
        ? assignment.locationIds
        : assignment.teacherIds;

    for (final id in ids) {
      final index = columns.indexWhere((c) => c.id == id);
      if (index < 0) continue;

      final top =
          (DutyTimeUtils.toMinutes(assignment.timeStart) - startHour * 60) *
              (hourHeight / 60);
      final height = ((DutyTimeUtils.toMinutes(assignment.timeEnd) -
                  DutyTimeUtils.toMinutes(assignment.timeStart)) *
              (hourHeight / 60))
          .clamp(40, 240)
          .toDouble();
      final color = schedule.groupingMode == DutyGroupingMode.location
          ? schedule.colorForId(
              assignment.teacherIds.isEmpty
                  ? assignment.id
                  : assignment.teacherIds.first,
            )
          : schedule.colorForId(
              assignment.locationIds.isEmpty
                  ? assignment.id
                  : assignment.locationIds.first,
            );

      yield Positioned(
        top: top.clamp(0, double.infinity).toDouble(),
        left: index * columnWidth + 8,
        width: columnWidth - 16,
        height: height,
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => DutyDetailSheet(assignment: assignment),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
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
                          child: Text(
                            assignment.dutyNameSnapshot,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (dutyProvider.isPrincipal && duty != null)
                          InkWell(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => DutyEditorDialog(duty: duty),
                            ),
                            child: const Icon(Icons.edit_outlined,
                                color: Colors.white, size: 16),
                          ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          assignment.teacherNameSnapshots.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          assignment.locationNameSnapshots.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      );
    }
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

String _formatHour(int hour) {
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour $suffix';
}

class _ColumnMeta {
  final String id;
  final String label;
  const _ColumnMeta(this.id, this.label);
}