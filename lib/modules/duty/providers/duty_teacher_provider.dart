import 'dart:async';
import 'package:flutter/material.dart';

import '../../teachers/models/teacher.dart';
import '../services/duty_external_service.dart';

class DutyTeacherProvider extends ChangeNotifier {
  DutyTeacherProvider({
    DutyExternalService? service,
  }) : _service = service ?? DutyExternalService() {
    _listenTeachers();
  }

  final DutyExternalService _service;

  StreamSubscription<List<TeacherRecord>>? _teacherSub;

  List<TeacherRecord> _teachers = [];
  bool _isLoading = true;
  String? _error;

  List<TeacherRecord> get teachers => _teachers;

  List<TeacherRecord> get activeTeachers =>
      _teachers.where((teacher) => teacher.status == 'active').toList();

  bool get isLoading => _isLoading;

  String? get error => _error;

  TeacherRecord? getTeacherById(String id) {
    try {
      return _teachers.firstWhere(
        (teacher) => teacher.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  void _listenTeachers() {
    _teacherSub = _service.fetchTeachers().listen(
      (items) {
        _teachers = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _teacherSub?.cancel();
    super.dispose();
  }
}