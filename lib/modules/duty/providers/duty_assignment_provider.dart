import 'dart:async';

import 'package:flutter/material.dart';

import '../models/duty_assignment.dart';
import '../models/duty_task_assignment.dart';
import '../services/duty_assignment_service.dart';
import '../services/duty_task_assignment_service.dart';
import '../utils/duty_time_utils.dart';

class DutyAssignmentProvider extends ChangeNotifier {
  DutyAssignmentProvider({
    DutyAssignmentService? assignmentService,
    DutyTaskAssignmentService? taskService,
  })  : _assignmentService = assignmentService ?? DutyAssignmentService(),
        _taskService = taskService ?? DutyTaskAssignmentService();

  final DutyAssignmentService _assignmentService;
  final DutyTaskAssignmentService _taskService;

  StreamSubscription<List<DutyAssignment>>? _assignmentSub;

  // Separate from `_assignmentSub`, which is scoped to `_selectedDate` for
  // the calendar/list screens. This one is scoped to the current teacher
  // across all dates, so the home screen can surface their next duty
  // regardless of whatever date the schedule screen happens to be on.
  StreamSubscription<List<DutyAssignment>>? _myAssignmentSub;
  List<DutyAssignment> _myAssignments = [];
  bool _isLoadingMyAssignments = true;

  List<DutyAssignment> _assignments = [];

  String? _currentUserId;
  String? _role;

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  String? _error;


  List<DutyAssignment> get assignments => _assignments;

  bool get isLoading => _isLoading;
  bool get isLoadingNextDuty => _isLoadingMyAssignments;
  String? get error => _error;

  String? get currentUserId => _currentUserId;
  bool get isPrincipal => _role == 'principal' || _role == 'admin';

  DateTime get selectedDate => _selectedDate;

  /// One-off lookup (not a live stream) of which dates in [from]..[to] have
  /// at least one assignment, used to grey out empty days in the date
  /// picker. There's no range-query on the service, so this pulls the full
  /// assignment list once and filters client-side -- fine for the picker's
  /// bounded ~5-week window, but would want a proper indexed range query if
  /// assignment volume grows a lot.
  Future<Set<DateTime>> datesWithAssignments({
    required DateTime from,
    required DateTime to,
  }) async {
    final all = await _assignmentService.getAssignments().first;
    final dates = <DateTime>{};
    for (final a in all) {
      final day = DateTime(a.date.year, a.date.month, a.date.day);
      if (!day.isBefore(from) && !day.isAfter(to)) {
        dates.add(day);
      }
    }
    return dates;
  }


  /// Assignments for the selected date, filtered for who should see them.
  ///
  /// - [locationFilterId], if set, narrows to that one venue.
  /// - [teacherFilterId], if set, narrows to that one teacher (works for
  ///   any role -- lets a principal or a teacher drill into someone
  ///   specific).
  /// - Otherwise: principals see everyone by default; teachers see only
  ///   their own assignments unless [showAllTeachers] is true.
  List<DutyAssignment> filteredAssignments({
    String? teacherFilterId,
    String? locationFilterId,
    bool showAllTeachers = false,
  }) {
    var list = _assignments;

    if (locationFilterId != null) {
      list = list.where((a) => a.locationId == locationFilterId).toList();
    }

    if (teacherFilterId != null) {
      list = list.where((a) => a.teacherIds.contains(teacherFilterId)).toList();
    } else if (!isPrincipal && !showAllTeachers) {
      list = list.where((a) => a.teacherIds.contains(_currentUserId)).toList();
    }

    return list;
  }

  /// The current teacher's earliest assignment that hasn't finished yet
  /// (i.e. its end time, using the assignment's own time snapshot, is
  /// still in the future) and isn't completed/cancelled. Used by the
  /// teacher home screen's "Next Duty" card.
  DutyAssignment? get nextUpcomingDutyAssignment {
    final now = DateTime.now();

    final candidates = _myAssignments.where((a) {
      if (a.status == DutyAssignmentStatus.completed ||
          a.status == DutyAssignmentStatus.cancelled) {
        return false;
      }
      return DutyTimeUtils.combine(a.date, a.timeEnd).isAfter(now);
    }).toList()
      ..sort((a, b) => DutyTimeUtils.combine(a.date, a.timeStart)
          .compareTo(DutyTimeUtils.combine(b.date, b.timeStart)));

    return candidates.isEmpty ? null : candidates.first;
  }

  void setUser({
    required String? userId,
    required String role,
  }) {
    if (_currentUserId == userId && _role == role) {
      return;
    }

    _currentUserId = userId;
    _role = role;

    _listenAssignments();
    _listenMyAssignments();

    notifyListeners();
  }


  void setDate(DateTime date) {
    _selectedDate = date;
    _listenAssignments();
    notifyListeners();
  }


  void _listenAssignments() {
    _assignmentSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _assignmentSub = _assignmentService
      .getAssignmentsByDate(_selectedDate)
      .listen((items) {
        _assignments = items;
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


  void _listenMyAssignments() {
    _myAssignmentSub?.cancel();
    if (_currentUserId == null) {
      _myAssignments = [];
      _isLoadingMyAssignments = false;
      return;
    }

    _isLoadingMyAssignments = true;

    _myAssignmentSub = _assignmentService
        .getAssignmentsByTeacher(_currentUserId!)
        .listen(
      (items) {
        _myAssignments = items;
        _isLoadingMyAssignments = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoadingMyAssignments = false;
        notifyListeners();
      },
    );
  }

  /// Live tasks for one specific assignment, regardless of who's on it.
  ///
  /// This used to have a teacher-scoped sibling (`tasksForAssignment`,
  /// backed by a `getTasksByTeacher` cache) that the home screen used for
  /// "my own" tasks on the theory that it would always match. It didn't
  /// reliably: the home screen's task list would sometimes come back empty
  /// even for the signed-in teacher's own duty, since it depended on two
  /// separately-queried caches (`getAssignmentsByTeacher` for which
  /// assignment to show, `getTasksByTeacher` for its tasks) staying in
  /// lockstep. Querying directly by `dutyAssignmentId` removes that
  /// dependency entirely -- this is now the only way tasks are fetched,
  /// everywhere.
  Stream<List<DutyTaskAssignment>> watchTasksForAssignment(
    String assignmentId,
  ) {
    return _taskService.getTasksByAssignment(assignmentId);
  }


  Future<void> completeTask({
    required String taskAssignmentId,
    required String teacherId,
    String? photoUrl,
  }) async {
    try {
      _error = null;
      notifyListeners();

      await _taskService.completeTask(
        id: taskAssignmentId,
        teacherId: teacherId,
        photoUrl: photoUrl,
      );

      await _syncAssignmentCompletion(taskAssignmentId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }


  Future<void> reopenTask(
    String taskAssignmentId,
  ) async {
    try {
      _error = null;
      notifyListeners();
      await _taskService.reopenTask(taskAssignmentId);

      await _syncAssignmentCompletion(taskAssignmentId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// "Once all tasks under a certain duty are completed, the duty would be
  /// marked as completed" -- and the reverse: reopening a task on an
  /// already-`completed` assignment un-completes it, since it's no longer
  /// true that everything's done.
  Future<void> _syncAssignmentCompletion(String taskAssignmentId) async {
    final task = await _taskService.getTaskAssignmentById(taskAssignmentId);
    if (task == null) return;

    final siblings =
        await _taskService.getTasksByAssignment(task.dutyAssignmentId).first;
    if (siblings.isEmpty) return;

    final assignment = await _assignmentService.getAssignmentById(task.dutyAssignmentId);
    if (assignment == null) return;
    if (assignment.status == DutyAssignmentStatus.cancelled) return;

    final allCompleted = siblings.every((t) => t.isCompleted);

    if (allCompleted && assignment.status != DutyAssignmentStatus.completed) {
      await _assignmentService.updateStatus(assignment.id, DutyAssignmentStatus.completed);
    } else if (!allCompleted && assignment.status == DutyAssignmentStatus.completed) {
      await _assignmentService.updateStatus(assignment.id, DutyAssignmentStatus.assigned);
    }
  }


  @override
  void dispose() {

    _assignmentSub?.cancel();
    _myAssignmentSub?.cancel();

    super.dispose();
  }
}