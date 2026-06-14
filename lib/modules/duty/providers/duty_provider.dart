import 'package:flutter/material.dart';
import '../models/duty.dart';
import '../services/duty_service.dart';

class DutyProvider extends ChangeNotifier {
  final DutyService _dutyService = DutyService();
  
  List<DutyAssignment> _todaysAssignments = [];
  bool _isLoading = true;

  List<DutyAssignment> get todaysAssignments => _todaysAssignments;
  bool get isLoading => _isLoading;

  void fetchAssignmentsForDate(String date) {
    _isLoading = true;
    notifyListeners();

    _dutyService.getAssignmentsForDate(date).listen((assignments) {
      _todaysAssignments = assignments;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> toggleChecklistItem(DutyAssignment assignment, String checklistId, String photoUrl) async {
    final updatedChecklist = assignment.checklist.map((item) {
      if (item.id == checklistId) {
        return DutyChecklistItem(
          id: item.id,
          description: item.description,
          isCompleted: !item.isCompleted,
          photoUrl: item.isCompleted ? null : photoUrl,
          completedAt: item.isCompleted ? null : DateTime.now(),
        );
      }
      return item;
    }).toList();

    final allCompleted = updatedChecklist.every((item) => item.isCompleted);
    final newStatus = allCompleted ? 'completed' : 'in-progress';

    final updatedAssignment = DutyAssignment(
      id: assignment.id,
      taskId: assignment.taskId,
      taskName: assignment.taskName,
      date: assignment.date,
      locationId: assignment.locationId,
      locationName: assignment.locationName,
      teacherIds: assignment.teacherIds,
      status: newStatus,
      timeStart: assignment.timeStart,
      timeEnd: assignment.timeEnd,
      isReplacement: assignment.isReplacement,
      checklist: updatedChecklist,
    );

    await _dutyService.updateAssignment(updatedAssignment);
  }
}
