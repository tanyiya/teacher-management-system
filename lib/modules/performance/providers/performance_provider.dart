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

  // Separate loading flags to avoid false "still loading" states
  bool _teachersLoading = false;
  bool _logsLoading = false;
  String? _error;

  int _monthFilter = 0;
  String _severityFilter = 'All';
  String _categoryFilter = 'All';

  // ─── Getters ────────────────────────────────────────────────────────────────

  List<PerformanceLog> get performanceLogs => _performanceLogs;
  List<WarningRecord> get warnings => _warnings;
  List<KpiNotification> get notifications => _notifications;
  List<TeacherRecord> get teachers => _teachers;
  Map<int, double> get monthlyScores => _monthlyScores;
  YearlyKpiRecord? get yearlyKpi => _yearlyKpi;
  String? get selectedTeacherId => _selectedTeacherId;

  // isLoading is true only when we have no teachers yet OR actively loading logs
  bool get isLoading => _teachersLoading || _logsLoading;
  String? get error => _error;

  TeacherRecord? get selectedTeacher {
    if (_selectedTeacherId == null || _teachers.isEmpty) return null;
    try {
      return _teachers.firstWhere((t) => t.id == _selectedTeacherId);
    } catch (_) {
      return null;
    }
  }

  List<PerformanceLog> get filteredPerformanceLogs {
    return _performanceLogs.where((log) {
      if (_monthFilter > 0 && log.timestamp.month != _monthFilter) return false;
      if (_severityFilter != 'All' && log.severity != _severityFilter) return false;
      if (_categoryFilter != 'All' && log.category != _categoryFilter) return false;
      return true;
    }).toList();
  }

  List<String> get severityOptions =>
      const ['All', 'Minor', 'Normal', 'Major', 'Critical'];

  List<String> get categoryOptions {
    final categories = _performanceLogs.map((l) => l.category).toSet().toList()
      ..sort();
    return ['All', ...categories];
  }

  List<String> get monthNames => const [
        'All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

  int get selectedMonthFilter => _monthFilter;
  String get selectedSeverityFilter => _severityFilter;
  String get selectedCategoryFilter => _categoryFilter;

  int get totalTeachers => _teachers.length;

  double get averageTeacherScore {
    if (_teachers.isEmpty) return 0;
    return _teachers.fold<double>(0, (s, t) => s + t.currentScore) /
        _teachers.length;
  }

  TeacherRecord? get highestPerformingTeacher {
    if (_teachers.isEmpty) return null;
    return _teachers.reduce((a, b) => a.currentScore >= b.currentScore ? a : b);
  }

  TeacherRecord? get lowestPerformingTeacher {
    if (_teachers.isEmpty) return null;
    return _teachers.reduce((a, b) => a.currentScore <= b.currentScore ? a : b);
  }

  double scoreForSeverity(String severity, {required bool isPositive}) =>
      _performanceService.scoreForSeverity(severity, isPositive: isPositive);

  // ─── Teacher loading ─────────────────────────────────────────────────────────

  /// Starts listening to the teachers collection.
  /// Auto-selects the first teacher if none is selected yet.
  void fetchTeachers() {
    _teachersLoading = true;
    _error = null;
    notifyListeners();

    _teachersSubscription?.cancel();
    _teachersSubscription =
        _performanceService.fetchAllTeachers().listen((teachers) {
      _teachers = teachers;
      _teachersLoading = false;

      // Auto-select first teacher only on initial load
      if (_selectedTeacherId == null && teachers.isNotEmpty) {
        _selectedTeacherId = teachers.first.id;
        _subscribeToTeacherData(_selectedTeacherId!);
      } else {
        notifyListeners();
      }
    }, onError: (e) {
      _error = 'Failed to load teachers: $e';
      _teachersLoading = false;
      notifyListeners();
    });
  }

  /// Switches the selected teacher and reloads their data.
  void selectTeacher(String teacherId) {
    if (_selectedTeacherId == teacherId) return;
    _selectedTeacherId = teacherId;
    clearFilters();
    _subscribeToTeacherData(teacherId);
  }

  /// Reloads everything. Safe to call repeatedly.
  Future<void> refreshAll() async {
    _error = null;

    // Re-subscribe to teachers (keeps existing selection)
    _teachersSubscription?.cancel();
    _teachersLoading = true;
    notifyListeners();

    _teachersSubscription =
        _performanceService.fetchAllTeachers().listen((teachers) {
      _teachers = teachers;
      _teachersLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to refresh teachers: $e';
      _teachersLoading = false;
      notifyListeners();
    });

    // Reload performance data for the currently selected teacher
    if (_selectedTeacherId != null) {
      _subscribeToTeacherData(_selectedTeacherId!);
    }
  }

  // ─── Teacher performance subscriptions ──────────────────────────────────────

  /// Cancels old subscriptions and opens fresh ones for [teacherId].
  void fetchTeacherPerformance(String teacherId) {
    _selectedTeacherId = teacherId;
    _subscribeToTeacherData(teacherId);
  }

  void _subscribeToTeacherData(String teacherId) {
    _logsLoading = true;
    _error = null;
    notifyListeners();

    // Cancel previous subscriptions before opening new ones
    _logsSubscription?.cancel();
    _warningsSubscription?.cancel();
    _kpiSubscription?.cancel();
    _notificationsSubscription?.cancel();

    _logsSubscription = _performanceService
        .getPerformanceLogsForTeacher(teacherId)
        .listen((logs) {
      _performanceLogs = logs;
      _monthlyScores = _buildMonthlyScores(logs, DateTime.now().year);
      _logsLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load logs: $e';
      _logsLoading = false;
      notifyListeners();
    });

    _warningsSubscription = _performanceService
        .getWarningsForTeacher(teacherId)
        .listen((warnings) {
      _warnings = warnings;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load warnings: $e';
      notifyListeners();
    });

    _notificationsSubscription = _performanceService
        .getNotificationsForTeacher(teacherId)
        .listen((notifications) {
      _notifications = notifications;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load notifications: $e';
      notifyListeners();
    });

    _kpiSubscription = _performanceService
        .getYearlyKpi(teacherId, DateTime.now().year)
        .listen((kpi) {
      _yearlyKpi = kpi;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load yearly KPI: $e';
      notifyListeners();
    });
  }

  // ─── Write operations ────────────────────────────────────────────────────────

  Future<void> addPerformanceLog(PerformanceLog log) async {
    try {
      await _performanceService.addPerformanceLog(log);
      // Streams auto-update; no manual refresh needed
    } catch (e) {
      _error = 'Failed to add log: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addWarningRecord(WarningRecord warning) async {
    try {
      await _performanceService.addWarningRecord(warning);
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
      _logsLoading = true;
      notifyListeners();
      await _performanceService.runAllKPIForYear(year, principalId);
      // Refresh selected teacher's KPI after batch run
      if (_selectedTeacherId != null) {
        _subscribeToTeacherData(_selectedTeacherId!);
      }
    } catch (e) {
      _error = 'Failed to run KPI: $e';
      rethrow;
    } finally {
      _logsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTeacherScore(String teacherId, double newScore) async {
    try {
      await _performanceService.updateTeacherScore(teacherId, newScore);
    } catch (e) {
      _error = 'Failed to update score: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> seedDummyPerformanceData() async {
    try {
      _logsLoading = true;
      _error = null;
      notifyListeners();
      await _performanceService.seedDummyPerformanceData();
      if (_selectedTeacherId != null) {
        _subscribeToTeacherData(_selectedTeacherId!);
      }
    } catch (e) {
      _error = 'Failed to seed data: $e';
      rethrow;
    } finally {
      _logsLoading = false;
      notifyListeners();
    }
  }

  // ─── Filters ─────────────────────────────────────────────────────────────────

  void updateFilters({int? month, String? severity, String? category}) {
    if (month != null) _monthFilter = month;
    if (severity != null) _severityFilter = severity;
    if (category != null) _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _monthFilter = 0;
    _severityFilter = 'All';
    _categoryFilter = 'All';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  Map<int, double> _buildMonthlyScores(List<PerformanceLog> logs, int year) {
    final scores = {for (var m = 1; m <= 12; m++) m: 0.0};
    for (final log in logs) {
      if (log.timestamp.year != year) continue;
      scores[log.timestamp.month] =
          (scores[log.timestamp.month] ?? 0.0) + log.amount;
    }
    return scores;
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