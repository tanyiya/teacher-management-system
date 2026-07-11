import 'dart:async';
import 'package:flutter/material.dart';

import '../models/duty.dart';
import '../models/duty_task.dart';
import '../models/duty_assignment.dart';
import '../models/duty_task_assignment.dart';
import '../services/duty_service.dart';
import '../services/duty_task_service.dart';
import '../services/duty_external_service.dart';
import '../services/duty_assignment_service.dart';
import '../services/duty_task_assignment_service.dart';
import '../services/duty_auto_scheduler.dart';
import '../utils/duty_time_utils.dart';
import '../../teachers/models/teacher.dart';
// NOTE: adjust this import to wherever NotificationService actually lives
// in your project -- assumed here to be lib/core/services/notification_service.dart.
import '../../../core/services/notification_service.dart';

/// Owns duty *definitions* -- the reusable templates (title, time window,
/// recurrence, locations, task checklist) that the principal edits.
///
/// This is distinct from [DutyAssignmentProvider], which owns the generated
/// day-to-day assignments. The old code mixed both concerns into a single
/// `DutyProvider`/`Duty` model; the new schema splits them, so the UI layer
/// needs both providers side by side. This provider does reach into the
/// assignment services on [updateDuty], though: editing a duty needs to
/// propagate to every assignment generated from it that hasn't happened
/// yet (see [_propagateToFutureAssignments]), and both [createDuty] and
/// [updateDuty] force an immediate [DutyAutoScheduler] run afterwards,
/// since a new duty or a changed time/venue/staffing requirement can leave
/// a gap or a conflict that shouldn't wait for the next routine check.
///
/// Also exposes the teacher roster (via [DutyExternalService]) since both
/// the duty editor and the swap flow need to know who's available.
class DutyProvider extends ChangeNotifier {
  DutyProvider({
    DutyService? dutyService,
    DutyTaskService? taskService,
    DutyExternalService? externalService,
    DutyAssignmentService? assignmentService,
    DutyTaskAssignmentService? taskAssignmentService,
    DutyAutoScheduler? scheduler,
    NotificationService? notificationService,
  })  : _dutyService = dutyService ?? DutyService(),
        _taskService = taskService ?? DutyTaskService(),
        _externalService = externalService ?? DutyExternalService(),
        _assignmentService = assignmentService ?? DutyAssignmentService(),
        _taskAssignmentService =
            taskAssignmentService ?? DutyTaskAssignmentService(),
        _scheduler = scheduler ?? DutyAutoScheduler(),
        _notificationService = notificationService ?? NotificationService() {
    _listenDuties();
    _listenTasks();
    _listenTeachers();
  }

  final DutyService _dutyService;
  final DutyTaskService _taskService;
  final DutyExternalService _externalService;
  final DutyAssignmentService _assignmentService;
  final DutyTaskAssignmentService _taskAssignmentService;
  final DutyAutoScheduler _scheduler;
  final NotificationService _notificationService;

  StreamSubscription<List<Duty>>? _dutySub;
  StreamSubscription<List<DutyTask>>? _taskSub;
  StreamSubscription<List<TeacherRecord>>? _teacherSub;

  List<Duty> _duties = [];
  List<DutyTask> _tasks = [];
  List<TeacherRecord> _teachers = [];

  String? _currentUserId;
  String _role = 'teacher';

  bool _isLoading = true;
  bool _isCheckingSchedule = false;
  String? _error;

  /// True while [ensureScheduleFilled] is running -- the schedule screen
  /// shows a blocking spinner during this, since the auto-scheduler is
  /// actively writing assignments and letting someone interact mid-write
  /// could show stale or half-updated data.
  bool get isCheckingSchedule => _isCheckingSchedule;

  List<Duty> get duties => _duties;
  List<TeacherRecord> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  bool get isPrincipal => _role == 'principal' || _role == 'admin';

  List<TeacherRecord> get activeTeachers =>
      _teachers.where((t) => t.status.toLowerCase() == 'active').toList();

  Duty? dutyById(String id) {
    for (final duty in _duties) {
      if (duty.id == id) return duty;
    }
    return null;
  }

  List<DutyTask> tasksForDuty(String dutyId) {
    final matching = _tasks.where((task) => task.dutyId == dutyId).toList();
    matching.sort((a, b) => a.sequence.compareTo(b.sequence));
    return matching;
  }

  void setUser({required String? userId, required String role}) {
    if (_currentUserId == userId && _role == role) return;
    _currentUserId = userId;
    _role = role;
    notifyListeners();
  }

  /// Called once when the schedule screen opens. Respects the daily
  /// throttle (see [DutyAutoScheduler.ensureScheduleFilled]) -- cheap to
  /// call on every open, since it's a no-op once it's already run today.
  /// Toggles [isCheckingSchedule] around the call so the screen can show a
  /// spinner while it's actively writing assignments.
  Future<void> ensureScheduleFilled() async {
    _isCheckingSchedule = true;
    notifyListeners();
    try {
      await _scheduler.ensureScheduleFilled();
    } finally {
      _isCheckingSchedule = false;
      notifyListeners();
    }
  }

  void _listenDuties() {
    _dutySub = _dutyService.getDuties().listen(
      (items) {
        _duties = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _listenTasks() {
    // A single stream of every duty task, grouped locally by dutyId. This
    // keeps the editor/detail screens from having to manage one
    // subscription per duty.
    _taskSub = _taskService.getDutyTasks().listen(
      (items) {
        _tasks = items;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void _listenTeachers() {
    _teacherSub = _externalService.fetchTeachers().listen(
      (items) {
        _teachers = items;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Creates a duty definition together with its task checklist.
  Future<void> createDuty(Duty duty, List<DutyTask> tasks) async {
    try {
      _error = null;
      final dutyId = await _dutyService.addDuty(duty);
      var sequence = 0;
      for (final task in tasks) {
        await _taskService.addDutyTask(
          task.copyWith(
            dutyId: dutyId,
            dutyNameSnapshot: duty.title,
            sequence: sequence++,
          ),
        );
      }
      // A brand new duty has no assignments at all yet -- don't make it
      // wait for tomorrow's routine check to get staffed.
      await _scheduler.ensureScheduleFilled(force: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Updates a duty definition and reconciles its task checklist: existing
  /// tasks (non-empty id) are updated in place, new ones (empty id) are
  /// added, and tasks no longer present in [tasks] are deleted.
  ///
  /// Also propagates the change to every assignment generated from this
  /// duty that hasn't happened yet (see [_propagateToFutureAssignments]),
  /// so editing a duty doesn't leave already-generated future assignments
  /// showing stale name/time/venue info.
  Future<void> updateDuty(Duty duty, List<DutyTask> tasks) async {
    try {
      _error = null;
      await _dutyService.updateDuty(duty);

      final existingIds = tasksForDuty(duty.id).map((t) => t.id).toSet();
      final keptIds = <String>{};
      var sequence = 0;

      for (final task in tasks) {
        final withMeta = task.copyWith(
          dutyId: duty.id,
          dutyNameSnapshot: duty.title,
          sequence: sequence++,
        );
        if (task.id.isEmpty) {
          await _taskService.addDutyTask(withMeta);
        } else {
          keptIds.add(task.id);
          await _taskService.updateDutyTask(withMeta);
        }
      }

      for (final removedId in existingIds.difference(keptIds)) {
        await _taskService.deleteDutyTask(removedId);
      }

      await _propagateToFutureAssignments(duty);

      // A time/venue/staffing change can introduce a missing assignment or
      // a teacher overlap right now -- force a fresh check instead of
      // waiting for the routine once-a-day one.
      await _scheduler.ensureScheduleFilled(force: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool _isStillPending(DutyAssignment assignment, DateTime now) {
    final alreadyHappened =
        !DutyTimeUtils.combine(assignment.date, assignment.timeEnd).isAfter(now);
    final resolved = assignment.status == DutyAssignmentStatus.completed ||
        assignment.status == DutyAssignmentStatus.cancelled;
    return !alreadyHappened && !resolved;
  }

  /// Brings every not-yet-happened assignment generated from [duty] in
  /// line with its latest definition:
  ///  - still-current venues get their name/title/time snapshots refreshed
  ///    (and their task snapshots refreshed to match, where the task still
  ///    exists on the duty)
  ///  - venues removed from the duty have their (future, non-completed)
  ///    assignment retired entirely, since there's nothing left to do there
  ///
  /// Deliberately does NOT create assignments for venues newly *added* to
  /// the duty -- that requires the auto-scheduler (which picks eligible
  /// teachers, checks leave, avoids overlaps, etc.), not just a data patch.
  /// Already-completed or already-cancelled assignments are left alone, as
  /// are ones whose time window has already passed.
  Future<void> _propagateToFutureAssignments(Duty duty) async {
    final now = DateTime.now();
    final assignments =
        await _assignmentService.getAssignmentsByDuty(duty.id).first;
    final currentTasks = await _taskService.getTasksByDuty(duty.id).first;
    final currentTaskById = {for (final t in currentTasks) t.id: t};
    final currentLocationIds = duty.locations.map((l) => l.id).toSet();
    final locationNameById = {for (final l in duty.locations) l.id: l.name};

    for (final assignment in assignments) {
      if (!_isStillPending(assignment, now)) continue;

      if (!currentLocationIds.contains(assignment.locationId)) {
        // Venue no longer part of this duty -- nothing left to assign here.
        await _taskAssignmentService.deleteTasksByAssignment(assignment.id);
        await _assignmentService.deleteAssignment(assignment.id);
        for (final teacherId in assignment.teacherIds) {
          await _notificationService.send(
            userId: teacherId,
            title: 'Duty cancelled',
            message: '${assignment.dutyNameSnapshot} at ${assignment.locationNameSnapshot} '
                'on ${_fmtDate(assignment.date)} was removed from your schedule.',
            type: 'duty_assignment',
            relatedId: assignment.id,
          );
        }
        continue;
      }

      final timeChanged =
          assignment.timeStart != duty.timeStart || assignment.timeEnd != duty.timeEnd;
      final newLocationName =
          locationNameById[assignment.locationId] ?? assignment.locationNameSnapshot;
      final locationRenamed = newLocationName != assignment.locationNameSnapshot;

      final refreshedAssignment = assignment.copyWith(
        dutyNameSnapshot: duty.title,
        timeStart: duty.timeStart,
        timeEnd: duty.timeEnd,
        locationNameSnapshot: newLocationName,
      );
      await _assignmentService.updateAssignment(refreshedAssignment);

      if (timeChanged || locationRenamed) {
        for (final teacherId in assignment.teacherIds) {
          await _notificationService.send(
            userId: teacherId,
            title: 'Duty updated',
            message: '${duty.title} on ${_fmtDate(assignment.date)} is now '
                '${duty.timeStart}-${duty.timeEnd} at $newLocationName.',
            type: 'duty_assignment',
            relatedId: assignment.id,
          );
        }
      }

      final taskAssignments =
          await _taskAssignmentService.getTasksByAssignment(assignment.id).first;
      final taskAssignmentByTaskId = {for (final ta in taskAssignments) ta.dutyTaskId: ta};

      // Existing task-assignments: refresh the ones whose task still
      // exists and changed wording, retire the ones whose task was
      // removed from the duty entirely.
      for (final ta in taskAssignments) {
        final matchingTask = currentTaskById[ta.dutyTaskId];
        if (matchingTask == null) {
          await _taskAssignmentService.deleteTaskAssignment(ta.id);
          continue;
        }
        if (matchingTask.title == ta.taskNameSnapshot) continue;
        await _taskAssignmentService.updateTaskAssignment(
          DutyTaskAssignment(
            id: ta.id,
            dutyAssignmentId: ta.dutyAssignmentId,
            dutyTaskId: ta.dutyTaskId,
            taskNameSnapshot: matchingTask.title,
            teacherIds: ta.teacherIds,
            teacherNameSnapshots: ta.teacherNameSnapshots,
            isCompleted: ta.isCompleted,
            photoUrl: ta.photoUrl,
            completedAt: ta.completedAt,
            completedByTeacherId: ta.completedByTeacherId,
          ),
        );
      }

      // Tasks added to the duty after this assignment was originally
      // generated have no task-assignment doc at all yet -- this was the
      // actual gap: the loop above only ever updated docs that already
      // existed, so a brand-new task never showed up on any
      // already-generated future assignment. Create one for each,
      // inheriting the assignment's current teacher(s).
      for (final task in currentTasks) {
        if (taskAssignmentByTaskId.containsKey(task.id)) continue;
        await _taskAssignmentService.addTaskAssignment(
          DutyTaskAssignment(
            id: '',
            dutyAssignmentId: assignment.id,
            dutyTaskId: task.id,
            taskNameSnapshot: task.title,
            teacherIds: refreshedAssignment.teacherIds,
            teacherNameSnapshots: refreshedAssignment.teacherNameSnapshots,
            isCompleted: false,
            photoUrl: null,
            completedAt: null,
            completedByTeacherId: null,
          ),
        );
      }
    }
  }

  /// Deletes the duty definition, its tasks (cascaded by the service
  /// itself), and every not-yet-happened assignment generated from it
  /// (which the service does NOT cascade -- assignments are a separate
  /// collection with no knowledge of duty deletion).
  Future<void> deleteDuty(String id) async {
    try {
      _error = null;

      final now = DateTime.now();
      final assignments = await _assignmentService.getAssignmentsByDuty(id).first;
      for (final assignment in assignments) {
        if (!_isStillPending(assignment, now)) continue;
        await _taskAssignmentService.deleteTasksByAssignment(assignment.id);
        await _assignmentService.deleteAssignment(assignment.id);
      }

      await _dutyService.deleteDuty(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  String _fmtDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  void dispose() {
    _dutySub?.cancel();
    _taskSub?.cancel();
    _teacherSub?.cancel();
    super.dispose();
  }
}