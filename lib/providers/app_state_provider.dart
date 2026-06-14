import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/teachers/models/teacher.dart';
import '../modules/teachers/services/teacher_service.dart';

class AppStateProvider extends ChangeNotifier {
  final TeacherService _teacherService = TeacherService();
  
  TeacherRecord? _currentUser;
  bool _isLoading = true;

  TeacherRecord? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AppStateProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    
    if (userId != null) {
      _currentUser = await _teacherService.getTeacherById(userId); // ← fetch user
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loginAs(TeacherRecord teacher) async {
    _currentUser = teacher;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', teacher.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    notifyListeners();
  }
}