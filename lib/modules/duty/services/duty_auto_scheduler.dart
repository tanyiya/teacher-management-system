import '../models/duty.dart';
import '../models/duty_location.dart';
import '../models/duty_task.dart';
import '../models/duty_assignment.dart';
import '../models/duty_task_assignment.dart';
import '../services/duty_service.dart';
import '../services/duty_task_service.dart';
import '../services/duty_assignment_service.dart';
import '../services/duty_task_assignment_service.dart';
import '../services/duty_external_service.dart';
import '../services/duty_scheduler_meta_service.dart';
import '../utils/duty_time_utils.dart';
import '../../teachers/models/teacher.dart';

/// Keeps the next 7 days of duty assignments filled in, automatically.
///
/// Runs on two triggers:
///  - Opening the schedule screen calls [ensureScheduleFilled] with
///    `force: false`. If it already ran today, this is a no-op (checked
///    via [DutySchedulerMetaService.getLastCheckedAt]) -- no point
///    re-scanning every single time the screen opens.
///  - Creating or editing a duty (time, venues, or minimum-teachers-per-
///    venue) calls it with `force: true`, since a change like that can
///    introduce a missing assignment or a teacher overlap *today*, and
///    that can't wait for tomorrow's routine check.
///
/// What "filled" means for each (duty, date, venue) in the window:
///  - No assignment exists yet -> create one, staffed via round-robin.
///  - An assignment exists but has fewer teachers than
///    `minTeachersPerVenue` (e.g. that was just raised) -> top it up.
///  - An assignment's current teacher(s) are now double-booked elsewhere
///    at an overlapping time (typically because a duty's time window was
///    just edited) -> swap the conflicting teacher(s) out for a fresh,
///    free round-robin pick.
///  - Assignments already `completed`/`cancelled`, or whose time window
///    has already passed, are left alone.
///
/// Deliberately out of scope for this pass:
///  - `DutyRecurrence.once` duties aren't generated at all -- the `Duty`
///    model has no field for "which specific date", so there's nothing to
///    schedule against yet.
///  - Teacher leave/unavailability isn't checked -- every `active` teacher
///    is treated as available. Noted as a known follow-up.
class DutyAutoScheduler {
  DutyAutoScheduler({
    DutyService? dutyService,
    DutyTaskService? taskService,
    DutyAssignmentService? assignmentService,
    DutyTaskAssignmentService? taskAssignmentService,
    DutyExternalService? externalService,
    DutySchedulerMetaService? metaService,
  })  : _dutyService = dutyService ?? DutyService(),
        _taskService = taskService ?? DutyTaskService(),
        _assignmentService = assignmentService ?? DutyAssignmentService(),
        _taskAssignmentService =
            taskAssignmentService ?? DutyTaskAssignmentService(),
        _externalService = externalService ?? DutyExternalService(),
        _metaService = metaService ?? DutySchedulerMetaService();

  final DutyService _dutyService;
  final DutyTaskService _taskService;
  final DutyAssignmentService _assignmentService;
  final DutyTaskAssignmentService _taskAssignmentService;
  final DutyExternalService _externalService;
  final DutySchedulerMetaService _metaService;

  static const int lookaheadDays = 7;

  Future<void> ensureScheduleFilled({bool force = false}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!force) {
      final lastChecked = await _metaService.getLastCheckedAt();
      if (lastChecked != null) {
        final lastCheckedDay =
            DateTime(lastChecked.year, lastChecked.month, lastChecked.day);
        if (!lastCheckedDay.isBefore(today)) return; // already ran today
      }
    }

    final duties = await _dutyService.getDuties().first;
    final teachers = (await _externalService.fetchTeachers().first)
        .where((t) => t.status.toLowerCase() == 'active')
        .toList();
    if (teachers.isEmpty || duties.isEmpty) {
      await _metaService.saveState(
        lastCheckedAt: now,
        rotationCursor: await _metaService.getRotationCursor(),
      );
      return;
    }

    var rotationCursor = await _metaService.getRotationCursor();
    final dates = List.generate(lookaheadDays, (i) => today.add(Duration(days: i)));

    // Cached per date and mutated as this run creates/updates assignments,
    // so a later duty on the same date sees teachers reserved by an
    // earlier one in this same pass (otherwise two duties at the same
    // time could round-robin the same "free" teacher onto both).
    final assignmentsByDate = <DateTime, List<DutyAssignment>>{};
    for (final date in dates) {
      assignmentsByDate[date] = await _assignmentService.getAssignmentsByDate(date).first;
    }

    for (final date in dates) {
      for (final duty in duties) {
        if (!_occursOn(duty, date)) continue;

        final tasksForDuty = await _taskService.getTasksByDuty(duty.id).first;

        for (final location in duty.locations) {
          rotationCursor = await _fillVenue(
            duty: duty,
            date: date,
            location: location,
            tasksForDuty: tasksForDuty,
            teachers: teachers,
            rotationCursor: rotationCursor,
            assignmentsByDate: assignmentsByDate,
            now: now,
          );
        }
      }
    }

    await _metaService.saveState(lastCheckedAt: now, rotationCursor: rotationCursor);
  }

  Future<int> _fillVenue({
    required Duty duty,
    required DateTime date,
    required DutyLocation location,
    required List<DutyTask> tasksForDuty,
    required List<TeacherRecord> teachers,
    required int rotationCursor,
    required Map<DateTime, List<DutyAssignment>> assignmentsByDate,
    required DateTime now,
  }) async {
    // Already over today (only relevant for the current day in the
    // window) -- nothing left to staff.
    if (!DutyTimeUtils.combine(date, duty.timeEnd).isAfter(now)) {
      return rotationCursor;
    }

    final dayAssignments = assignmentsByDate[date]!;
    DutyAssignment? existing;
    for (final a in dayAssignments) {
      if (a.dutyId == duty.id && a.locationId == location.id) {
        existing = a;
        break;
      }
    }

    if (existing != null &&
        (existing.status == DutyAssignmentStatus.completed ||
            existing.status == DutyAssignmentStatus.cancelled)) {
      return rotationCursor; // already resolved one way or another, leave it
    }

    final busy = <String>{};
    for (final a in dayAssignments) {
      if (existing != null && a.id == existing.id) continue;
      if (DutyTimeUtils.rangesOverlap(duty.timeStart, duty.timeEnd, a.timeStart, a.timeEnd)) {
        busy.addAll(a.teacherIds);
      }
    }

    final currentIds = existing?.teacherIds ?? const <String>[];
    final currentNames = existing?.teacherNameSnapshots ?? const <String>[];

    final keptIds = <String>[];
    final keptNames = <String>[];
    for (var i = 0; i < currentIds.length; i++) {
      if (busy.contains(currentIds[i])) continue; // now double-booked elsewhere, drop
      keptIds.add(currentIds[i]);
      keptNames.add(i < currentNames.length ? currentNames[i] : currentIds[i]);
    }

    final needed = duty.minTeachersPerVenue - keptIds.length;
    if (needed <= 0 && keptIds.length == currentIds.length) {
      return rotationCursor; // fully staffed, no conflicts to fix
    }

    final unavailable = {...busy, ...keptIds};
    final picks = <TeacherRecord>[];
    var attempts = 0;
    while (picks.length < needed && attempts < teachers.length * 2) {
      final candidate = teachers[rotationCursor % teachers.length];
      rotationCursor++;
      attempts++;
      if (unavailable.contains(candidate.id)) continue;
      if (picks.any((p) => p.id == candidate.id)) continue;
      picks.add(candidate);
      unavailable.add(candidate.id);
    }

    final finalIds = [...keptIds, ...picks.map((t) => t.id)];
    final finalNames = [...keptNames, ...picks.map((t) => t.fullName)];

    if (finalIds.isEmpty) {
      // No eligible teacher at all right now -- leave it unfilled rather
      // than write an assignment with nobody on it.
      return rotationCursor;
    }

    if (existing == null) {
      final assignment = DutyAssignment(
        id: '',
        dutyId: duty.id,
        dutyNameSnapshot: duty.title,
        date: date,
        timeStart: duty.timeStart,
        timeEnd: duty.timeEnd,
        locationId: location.id,
        locationNameSnapshot: location.name,
        teacherIds: finalIds,
        teacherNameSnapshots: finalNames,
        status: DutyAssignmentStatus.assigned,
      );
      final assignmentId = await _assignmentService.addAssignment(assignment);
      final saved = DutyAssignment(
        id: assignmentId,
        dutyId: assignment.dutyId,
        dutyNameSnapshot: assignment.dutyNameSnapshot,
        date: assignment.date,
        timeStart: assignment.timeStart,
        timeEnd: assignment.timeEnd,
        locationId: assignment.locationId,
        locationNameSnapshot: assignment.locationNameSnapshot,
        teacherIds: assignment.teacherIds,
        teacherNameSnapshots: assignment.teacherNameSnapshots,
        status: assignment.status,
      );
      dayAssignments.add(saved);

      for (final task in tasksForDuty) {
        await _taskAssignmentService.addTaskAssignment(
          DutyTaskAssignment(
            id: '',
            dutyAssignmentId: assignmentId,
            dutyTaskId: task.id,
            taskNameSnapshot: task.title,
            teacherIds: finalIds,
            teacherNameSnapshots: finalNames,
            isCompleted: false,
            photoUrl: null,
            completedAt: null,
            completedByTeacherId: null,
          ),
        );
      }
    } else {
      final updated = existing.copyWith(teacherIds: finalIds, teacherNameSnapshots: finalNames);
      await _assignmentService.updateAssignment(updated);

      final index = dayAssignments.indexWhere((a) => a.id == existing!.id);
      if (index != -1) dayAssignments[index] = updated;

      final relatedTasks =
          await _taskAssignmentService.getTasksByAssignment(existing.id).first;
      for (final ta in relatedTasks) {
        await _taskAssignmentService.updateTaskAssignment(
          DutyTaskAssignment(
            id: ta.id,
            dutyAssignmentId: ta.dutyAssignmentId,
            dutyTaskId: ta.dutyTaskId,
            taskNameSnapshot: ta.taskNameSnapshot,
            teacherIds: finalIds,
            teacherNameSnapshots: finalNames,
            isCompleted: ta.isCompleted,
            photoUrl: ta.photoUrl,
            completedAt: ta.completedAt,
            completedByTeacherId: ta.completedByTeacherId,
          ),
        );
      }
    }

    return rotationCursor;
  }

  bool _occursOn(Duty duty, DateTime date) {
    switch (duty.recurrence) {
      case DutyRecurrence.daily:
        return true;
      case DutyRecurrence.weekly:
        return date.weekday == duty.recurrenceDayOfWeek;
      case DutyRecurrence.monthly:
        return date.day == duty.recurrenceDayOfMonth;
      case DutyRecurrence.once:
        // No specific-date field on `Duty` yet, so there's nothing to
        // schedule this against -- skipped until that's added.
        return false;
    }
  }
}