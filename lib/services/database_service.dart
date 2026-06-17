import '../modules/teachers/services/teacher_service.dart';
import '../modules/duty/services/duty_service.dart';
import '../modules/training/services/training_service.dart';
import '../modules/leave/services/leave_service.dart';
import '../modules/report/services/report_services.dart';
import '../core/services/notification_service.dart';

import '../modules/teachers/models/teacher.dart';
import '../modules/duty/models/duty.dart';
import '../modules/training/models/training.dart';
import '../modules/leave/models/leave.dart';
import '../modules/report/models/report.dart';
import '../core/models/notification.dart';

class DatabaseService {
  final TeacherService _teacherService = TeacherService();
  final DutyService _dutyService = DutyService();
  final TrainingService _trainingService = TrainingService();
  final LeaveService _leaveService = LeaveService();
  final ReportService _reportService = ReportService();
  final NotificationService _notificationService = NotificationService();

  // Teachers
  Stream<List<TeacherRecord>> getTeachers() => _teacherService.getTeachers();

  // Duty
  Stream<List<DutyTask>> getDutyTasks() => _dutyService.getDutyTasks();
  Stream<List<DutyAssignment>> getAssignmentsForDate(String date) => _dutyService.getAssignmentsForDate(date);
  Future<void> updateAssignment(DutyAssignment assignment) => _dutyService.updateAssignment(assignment);

  // Training
  Stream<List<TrainingPost>> getTrainingPosts() => _trainingService.getTrainingPosts();

  // Leaves
  Stream<List<LeaveRecord>> getLeavesForTeacher(String teacherId) => _leaveService.getLeavesForTeacher(teacherId);

  // Reports
  Stream<List<FacilityReport>> getReports() => _reportService.getReports();

  // Notifications
  Stream<List<AlertNotification>> getNotifications(String userId) => _notificationService.getNotifications(userId);
}
