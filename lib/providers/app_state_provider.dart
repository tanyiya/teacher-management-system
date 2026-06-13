import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teacher.dart';
import '../services/database_service.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
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
      // In a real app, fetch from Firestore. Mocking direct assignment for now
      // Or use a stream subscription.
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
