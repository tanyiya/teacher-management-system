import 'dart:async';
import 'package:flutter/material.dart';

import '../models/duty.dart';
import '../models/duty_task.dart';
import '../services/duty_service.dart';
import '../services/duty_task_service.dart';
import '../services/duty_external_service.dart';
import '../../teachers/models/teacher.dart';

/// Owns duty *definitions* -- the reusable templates (title, time window,
/// recurrence, locations, task checklist) that the principal edits.
///
/// This is distinct from [DutyAssignmentProvider], which owns the generated
/// day-to-day assignments. The old code mixed both concerns into a single
/// `DutyProvider`/`Duty` model; the new schema splits them, so the UI layer
/// needs both providers side by side.
///
/// Also exposes the teacher roster (via [DutyExternalService]) since both
/// the duty editor and the swap flow need to know who's available.
class DutyProvider extends ChangeNotifier {
  DutyProvider({
    DutyService? dutyService,
    DutyTaskService? taskService,
    DutyExternalService? externalService,
  })  : _dutyService = dutyService ?? DutyService(),
        _taskService = taskService ?? DutyTaskService(),
        _externalService = externalService ?? DutyExternalService() {
    _listenDuties();
    _listenTasks();
    _listenTeachers();
  }

  final DutyService _dutyService;
  final DutyTaskService _taskService;
  final DutyExternalService _externalService;

  StreamSubscription<List<Duty>>? _dutySub;
  StreamSubscription<List<DutyTask>>? _taskSub;
  StreamSubscription<List<TeacherRecord>>? _teacherSub;

  List<Duty> _duties = [];
  List<DutyTask> _tasks = [];
  List<TeacherRecord> _teachers = [];

  String? _currentUserId;
  String _role = 'teacher';

  bool _isLoading = true;
  String? _error;

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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Updates a duty definition and reconciles its task checklist: existing
  /// tasks (non-empty id) are updated in place, new ones (empty id) are
  /// added, and tasks no longer present in [tasks] are deleted.
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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDuty(String id) async {
    try {
      _error = null;
      await _dutyService.deleteDuty(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _dutySub?.cancel();
    _taskSub?.cancel();
    _teacherSub?.cancel();
    super.dispose();
  }
}