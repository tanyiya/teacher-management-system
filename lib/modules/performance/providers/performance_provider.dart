import 'package:flutter/material.dart';

import '../models/performance.dart';
import '../services/performance_service.dart';

class PerformanceProvider extends ChangeNotifier {
  final PerformanceService _performanceService = PerformanceService();

  List<PerformanceLog> _performanceLogs = [];
  List<WarningRecord> _warnings = [];
  bool _isLoading = true;

  List<PerformanceLog> get performanceLogs => _performanceLogs;
  List<WarningRecord> get warnings => _warnings;
  bool get isLoading => _isLoading;

  void fetchTeacherPerformance(String teacherId) {
    _isLoading = true;
    notifyListeners();

    _performanceService.getPerformanceLogsForTeacher(teacherId).listen((logs) {
      _performanceLogs = logs;
      _isLoading = false;
      notifyListeners();
    });

    _performanceService.getWarningsForTeacher(teacherId).listen((warnings) {
      _warnings = warnings;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addPerformanceLog(PerformanceLog log) async {
    await _performanceService.addPerformanceLog(log);
  }

  Future<void> addWarningRecord(WarningRecord warning) async {
    await _performanceService.addWarningRecord(warning);
  }
}
