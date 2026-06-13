import 'package:flutter/material.dart';
import '../models/training.dart';
import '../services/database_service.dart';

class TrainingProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<TrainingPost> _posts = [];
  bool _isLoading = true;

  List<TrainingPost> get posts => _posts;
  bool get isLoading => _isLoading;

  TrainingProvider() {
    _initStreams();
  }

  void _initStreams() {
    _dbService.getTrainingPosts().listen((postsList) {
      _posts = postsList;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> applyForCourse(TrainingPost post, String teacherId, String teacherName) async {
    final application = TrainingApplication(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Mock ID
      postId: post.id,
      trainingTitle: post.trainingTitle ?? 'Unknown Course',
      teacherId: teacherId,
      teacherName: teacherName,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _dbService.applyForTraining(application);
  }
}
