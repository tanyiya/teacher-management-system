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
  StreamSubscription<List<DutyTaskAssignment>>? _taskSub;

  // Separate from `_assignmentSub`, which is scoped to `_selectedDate` for
  // the calendar/list screens. This one is scoped to the current teacher
  // across all dates, so the home screen can surface their next duty
  // regardless of whatever date the schedule screen happens to be on.
  StreamSubscription<List<DutyAssignment>>? _myAssignmentSub;
  List<DutyAssignment> _myAssignments = [];
  bool _isLoadingMyAssignments = true;

  List<DutyAssignment> _assignments = [];
  List<DutyTaskAssignment> _tasks = [];

  String? _currentUserId;
  String? _role;

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  String? _error;


  List<DutyAssignment> get assignments => _assignments;
  List<DutyTaskAssignment> get tasks => _tasks;

  bool get isLoading => _isLoading;
  bool get isLoadingNextDuty => _isLoadingMyAssignments;
  String? get error => _error;

  String? get currentUserId => _currentUserId;
  bool get isPrincipal => _role == 'principal' || _role == 'admin';

  DateTime get selectedDate => _selectedDate;


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
    _listenTasks();
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


  void _listenTasks() {
    _taskSub?.cancel();
    if (_currentUserId == null) {
      _tasks = [];
      return;
    }

    _taskSub =
        _taskService
            .getTasksByTeacher(_currentUserId!)
            .listen(
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

  List<DutyTaskAssignment> tasksForAssignment(
    String assignmentId,
  ) {
    return _tasks
        .where((task) =>task.dutyAssignmentId == assignmentId,)
        .toList();
  }

  /// Live tasks for one specific assignment, regardless of who's on it.
  ///
  /// `tasks`/`tasksForAssignment` above are scoped to the current
  /// signed-in teacher (`getTasksByTeacher`), which is right for the home
  /// screen's "my next duty" card but wrong here: opening a duty's details
  /// from the calendar or list screens needs to show its tasks even when
  /// viewing someone else's duty (or browsing as principal), so this goes
  /// straight to the assignment-scoped query instead of the teacher-scoped
  /// cache.
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
      await _taskService.reopenTask(taskAssignmentId,);

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }


  @override
  void dispose() {

    _assignmentSub?.cancel();
    _taskSub?.cancel();
    _myAssignmentSub?.cancel();

    super.dispose();
  }
}