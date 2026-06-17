import 'dart:async';

import 'package:flutter/material.dart';

import '../../teachers/models/teacher.dart';
import '../models/duty.dart';
import '../services/duty_service.dart';

class DutyProvider extends ChangeNotifier {
  DutyProvider({DutyService? dutyService})
      : _dutyService = dutyService ?? DutyService() {
    loadForSelectedDate();
    _listenLocations();
    _listenTeachers();
  }

  final DutyService _dutyService;
  StreamSubscription<List<Duty>>? _dutySub;
  StreamSubscription<List<Duty>>? _upcomingSub;
  StreamSubscription<List<DutyLocation>>? _locationSub;
  StreamSubscription<List<TeacherRecord>>? _teacherSub;

  DateTime _selectedDate = DateTime.now();
  DutyViewMode _viewMode = DutyViewMode.calendar;
  DutyGroupingMode _groupingMode = DutyGroupingMode.location;
  DutyUserRole _userRole = DutyUserRole.teacher;
  String? _currentTeacherId;
  String? _currentTeacherName;
  String? _teacherFilterId;
  String? _locationFilterId;
  List<Duty> _duties = [];
  List<Duty> _upcomingDuties = [];
  List<DutyLocation> _locations = [];
  List<TeacherRecord> _teachers = [];
  bool _isLoading = true;
  String? _error;
  DutySwap? _lastSwap;

  DateTime get selectedDate => _selectedDate;
  DutyViewMode get viewMode => _viewMode;
  DutyGroupingMode get groupingMode => _groupingMode;
  DutyUserRole get userRole => _userRole;
  String? get currentTeacherId => _currentTeacherId;
  String? get currentTeacherName => _currentTeacherName;
  List<Duty> get duties => _filteredDuties();
  List<Duty> get upcomingDuties => _upcomingDuties;
  Duty? get nextUpcomingDuty =>
      _upcomingDuties.isEmpty ? null : _upcomingDuties.first;
  List<DutyLocation> get locations => _locations;
  List<TeacherRecord> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DutySwap? get lastSwap => _lastSwap;
  String? get teacherFilterId => _teacherFilterId;
  String? get locationFilterId => _locationFilterId;
  bool get isPrincipal => _userRole == DutyUserRole.principal;

  List<Duty> get todoDuties =>
      duties.where((duty) => !duty.isCompleted).toList();
  List<Duty> get completedDuties =>
      duties.where((duty) => duty.isCompleted).toList();

  void setUser({
    required String? teacherId,
    required String? teacherName,
    required String role,
  }) {
    final lower = role.toLowerCase();
    final nextRole = lower == 'principal' || lower == 'admin'
        ? DutyUserRole.principal
        : DutyUserRole.teacher;
    if (_currentTeacherId == teacherId &&
        _currentTeacherName == teacherName &&
        _userRole == nextRole) {
      return;
    }
    _currentTeacherId = teacherId;
    _currentTeacherName = teacherName;
    _userRole = nextRole;
    _listenUpcomingDuties();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    final now = DateTime.now();
    final min = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 10));
    final max =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 10));
    final onlyDate = DateTime(date.year, date.month, date.day);
    if (onlyDate.isBefore(min) || onlyDate.isAfter(max)) return;
    _selectedDate = onlyDate;
    loadForSelectedDate();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == DutyViewMode.calendar
        ? DutyViewMode.list
        : DutyViewMode.calendar;
    notifyListeners();
  }

  void setGroupingMode(DutyGroupingMode mode) {
    _groupingMode = mode;
    notifyListeners();
  }

  void setTeacherFilter(String? id) {
    _teacherFilterId = id;
    notifyListeners();
  }

  void setLocationFilter(String? id) {
    _locationFilterId = id;
    notifyListeners();
  }

  void loadForSelectedDate() {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _dutySub?.cancel();
    _dutySub = _dutyService.fetchDutiesByDate(_selectedDate).listen((items) {
      _duties = items;
      _isLoading = false;
      notifyListeners();
    }, onError: (Object err) {
      _error = err.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> createDuty(Duty duty) async {
    await _guard(() async {
      await _dutyService.createRecurringDuties(duty);
    });
  }

  Future<void> updateDuty(Duty duty) async {
    await _guard(() => _dutyService.updateDuty(duty));
  }

  Future<void> deleteDuty(String dutyId) async {
    await _guard(() => _dutyService.deleteDuty(dutyId));
  }

  Future<DutyLocation?> addLocation(String name) async {
    try {
      return await _dutyService.addLocation(name);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> completeTask({
    required Duty duty,
    required String taskId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final teacherId = _currentTeacherId;
    if (teacherId == null) {
      _error = 'No signed-in teacher found.';
      notifyListeners();
      return;
    }
    await _guard(() => _dutyService.completeTaskWithProof(
          duty: duty,
          taskId: taskId,
          teacherId: teacherId,
          imageBytes: imageBytes,
          fileName: fileName,
        ));
  }

  Future<List<String>> eligibleSwapTeacherIds(Duty duty) {
    return _dutyService.findEligibleTeacherIds(duty);
  }

  Future<void> requestSwap(Duty duty, String toTeacherId,
      {String? fromTeacherId}) async {
    final sourceTeacherId = fromTeacherId ??
        (isPrincipal
            ? (duty.teacherIds.isEmpty ? null : duty.teacherIds.first)
            : _currentTeacherId);
    if (sourceTeacherId == null) return;
    await _guard(() async {
      _lastSwap = await _dutyService.requestSwap(
        duty: duty,
        fromTeacherId: sourceTeacherId,
        toTeacherId: toTeacherId,
        requestedBy: _currentTeacherId ?? sourceTeacherId,
        requestedByPrincipal: isPrincipal,
      );
    });
  }

  bool canCompleteTask(Duty duty) => _dutyService.canCompleteTask(duty);

  bool canRequestSwap(Duty duty) {
    if (isPrincipal) return true;
    final teacherId = _currentTeacherId;
    return teacherId != null &&
        duty.teacherIds.contains(teacherId) &&
        _dutyService.canRequestSwap(duty);
  }

  Color colorForTeacher(String teacherId) =>
      _stableColor(teacherId, _teacherPalette);

  Color colorForLocation(String locationId) =>
      _stableColor(locationId, _locationPalette);

  void _listenLocations() {
    _locationSub = _dutyService.fetchLocations().listen((items) {
      _locations = items;
      notifyListeners();
    });
  }

  void _listenTeachers() {
    _teacherSub = _dutyService.fetchTeachers().listen((items) {
      _teachers = items;
      notifyListeners();
    });
  }

  void _listenUpcomingDuties() {
    _upcomingSub?.cancel();
    final teacherId = _currentTeacherId;
    if (teacherId == null) {
      _upcomingDuties = [];
      return;
    }
    _upcomingSub =
        _dutyService.fetchUpcomingByTeacher(teacherId).listen((items) {
      _upcomingDuties = items;
      notifyListeners();
    });
  }

  List<Duty> _filteredDuties() {
    Iterable<Duty> result = _duties;
    if (!isPrincipal && _currentTeacherId != null) {
      result =
          result.where((duty) => duty.teacherIds.contains(_currentTeacherId));
    }
    if (_teacherFilterId != null && _teacherFilterId!.isNotEmpty) {
      result =
          result.where((duty) => duty.teacherIds.contains(_teacherFilterId));
    }
    if (_locationFilterId != null && _locationFilterId!.isNotEmpty) {
      result = result.where((duty) =>
          duty.locations.any((location) => location.id == _locationFilterId));
    }
    return result.toList();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      _error = null;
      notifyListeners();
      await action();
    } catch (err) {
      _error = err.toString();
      notifyListeners();
    }
  }

  Color _stableColor(String id, List<Color> palette) {
    if (id.isEmpty) return palette.first;
    final hash = id.codeUnits.fold<int>(0, (value, unit) => value + unit);
    return palette[hash % palette.length];
  }

  @override
  void dispose() {
    _dutySub?.cancel();
    _upcomingSub?.cancel();
    _locationSub?.cancel();
    _teacherSub?.cancel();
    super.dispose();
  }
}

const _teacherPalette = [
  Color(0xff2563eb),
  Color(0xff059669),
  Color(0xffdc2626),
  Color(0xff7c3aed),
  Color(0xff0891b2),
  Color(0xffc2410c),
  Color(0xff4f46e5),
];

const _locationPalette = [
  Color(0xff0f766e),
  Color(0xffb45309),
  Color(0xffbe123c),
  Color(0xff4338ca),
  Color(0xff047857),
  Color(0xff0369a1),
  Color(0xffa21caf),
];
