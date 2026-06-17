import 'dart:async';

import 'package:flutter/material.dart';

import '../../teachers/models/teacher.dart';
import '../models/performance.dart';
import '../services/performance_service.dart';

class PerformanceProvider extends ChangeNotifier {
  final PerformanceService _performanceService = PerformanceService();

  StreamSubscription<List<PerformanceLog>>? _logsSubscription;
  StreamSubscription<List<WarningRecord>>? _warningsSubscription;
  StreamSubscription<YearlyKpiRecord?>? _kpiSubscription;
  StreamSubscription<List<KpiNotification>>? _notificationsSubscription;
  StreamSubscription<List<TeacherRecord>>? _teachersSubscription;

  List<PerformanceLog> _performanceLogs = [];
  List<WarningRecord> _warnings = [];
  List<KpiNotification> _notifications = [];
  List<TeacherRecord> _teachers = [];
  Map<int, double> _monthlyScores = {};
  YearlyKpiRecord? _yearlyKpi;
  String? _selectedTeacherId;
  bool _isLoading = true;
  String? _error;

  List<PerformanceLog> get performanceLogs => _performanceLogs;
  List<WarningRecord> get warnings => _warnings;
  List<KpiNotification> get notifications => _notifications;
  List<TeacherRecord> get teachers => _teachers;
  Map<int, double> get monthlyScores => _monthlyScores;
  YearlyKpiRecord? get yearlyKpi => _yearlyKpi;
  String? get selectedTeacherId => _selectedTeacherId;
  TeacherRecord? get selectedTeacher {
    for (final teacher in _teachers) {
      if (teacher.id == _selectedTeacherId) return teacher;
    }
    return null;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;

  double scoreForSeverity(String severity, {required bool isPositive}) {
    return _performanceService.scoreForSeverity(
      severity,
      isPositive: isPositive,
    );
  }

  void fetchTeachers() {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _teachersSubscription?.cancel();
    _teachersSubscription = _performanceService.fetchAllTeachers().listen((teachers) {
      _teachers = teachers;
      if (_selectedTeacherId == null && teachers.isNotEmpty) {
        _selectedTeacherId = teachers.first.id;
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to fetch teachers: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  void selectTeacher(String teacherId) {
    if (_selectedTeacherId == teacherId) return;
    _selectedTeacherId = teacherId;
    fetchTeacherPerformance(teacherId);
  }

  void fetchTeacherPerformance(String teacherId) {
    _selectedTeacherId = teacherId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    _logsSubscription?.cancel();
    _warningsSubscription?.cancel();
    _kpiSubscription?.cancel();
    _notificationsSubscription?.cancel();

    _logsSubscription =
        _performanceService.getPerformanceLogsForTeacher(teacherId).listen((logs) {
      _performanceLogs = logs;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to fetch performance logs: $e';
      _isLoading = false;
      notifyListeners();
    });

    _warningsSubscription =
        _performanceService.getWarningsForTeacher(teacherId).listen((warnings) {
      _warnings = warnings;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to fetch warnings: $e';
      _isLoading = false;
      notifyListeners();
    });

    _notificationsSubscription = _performanceService
        .getNotificationsForTeacher(teacherId)
        .listen((notifications) {
      _notifications = notifications;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to fetch notifications: $e';
      _isLoading = false;
      notifyListeners();
    });

    _kpiSubscription =
        _performanceService.getYearlyKpi(teacherId, DateTime.now().year).listen((kpi) {
      _yearlyKpi = kpi;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to fetch yearly KPI: $e';
      _isLoading = false;
      notifyListeners();
    });

    _performanceService
        .calculateMonthlyScores(teacherId, DateTime.now().year)
        .then((scores) {
      if (_selectedTeacherId != teacherId) return;
      _monthlyScores = scores;
      notifyListeners();
    }).catchError((e) {
      if (_selectedTeacherId != teacherId) return;
      _error = 'Failed to calculate monthly scores: $e';
      notifyListeners();
    });
  }

  Future<void> addPerformanceLog(PerformanceLog log) async {
    try {
      await _performanceService.addPerformanceLog(log);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add performance log: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addWarningRecord(WarningRecord warning) async {
    try {
      await _performanceService.addWarningRecord(warning);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add warning: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<int, double>> fetchMonthlyScores(String teacherId, int year) async {
    try {
      _monthlyScores = await _performanceService.calculateMonthlyScores(teacherId, year);
      notifyListeners();
      return _monthlyScores;
    } catch (e) {
      _error = 'Failed to calculate monthly scores: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<YearlyKpiRecord> calculateYearlyKPI(
      String teacherId, int year, String principalId) async {
    try {
      return await _performanceService.calculateYearlyKPI(teacherId, year, principalId);
    } catch (e) {
      _error = 'Failed to calculate yearly KPI: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> runAllKPIForYear(int year, String principalId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _performanceService.runAllKPIForYear(year, principalId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to run KPI calculation: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTeacherScore(String teacherId, double newScore) async {
    try {
      await _performanceService.updateTeacherScore(teacherId, newScore);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update teacher score: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> seedDummyPerformanceData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _performanceService.seedDummyPerformanceData();
      if (_selectedTeacherId != null) {
        fetchTeacherPerformance(_selectedTeacherId!);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to seed dummy performance data: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    _warningsSubscription?.cancel();
    _kpiSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _teachersSubscription?.cancel();
    super.dispose();
  }
}
