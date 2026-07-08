// import 'dart:async';
// import 'package:flutter/material.dart';

// import '../models/duty_location.dart';
// import '../services/duty_task_assignment_service.dart';

// class DutyTaskAssignmentProvider extends ChangeNotifier {
//   final DutyTaskAssignmentService _service;

//   bool _isLoading = false;
//   String? _error;

//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   Future<void> completeTask({
//     required String assignmentId,
//     required String teacherId,
//     required String imageBytes,
//     required String fileName,
//   });

//   bool canCompleteTask(DutyTaskAssignment assignment);
// }