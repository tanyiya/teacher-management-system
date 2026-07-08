import 'package:cloud_firestore/cloud_firestore.dart';

class DutyTaskAssignment {
  final String id;
  final String dutyAssignmentId;
  final String dutyTaskId;
  final String taskNameSnapshot;
  final List<String> teacherIds;
  final List<String> teacherNameSnapshots;
  final bool isCompleted;
  final String? photoUrl;
  final DateTime? completedAt;
  final String? completedByTeacherId;

  const DutyTaskAssignment({
    required this.id,
    required this.dutyAssignmentId,
    required this.dutyTaskId,
    required this.taskNameSnapshot,
    required this.teacherIds,
    required this.teacherNameSnapshots,
    this.isCompleted = false,
    this.photoUrl,
    this.completedAt,
    this.completedByTeacherId,
  });

  factory DutyTaskAssignment.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return DutyTaskAssignment(
      id: id,
      dutyAssignmentId: data['dutyAssignmentId']?.toString() ?? '',
      dutyTaskId: data['dutyTaskId']?.toString() ?? '',
      taskNameSnapshot: data['taskNameSnapshot']?.toString() ?? '',

      teacherIds: List<String>.from(data['teacherIds'] ?? [],),
      teacherNameSnapshots: List<String>.from(data['teacherNameSnapshots'] ?? [],),

      isCompleted: data['isCompleted'] == true,
      photoUrl: data['photoUrl']?.toString(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedByTeacherId: data['completedByTeacherId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dutyAssignmentId': dutyAssignmentId,
      'dutyTaskId': dutyTaskId,
      'taskNameSnapshot': taskNameSnapshot,

      'teacherIds': teacherIds,
      'teacherNameSnapshots': teacherNameSnapshots,

      'isCompleted': isCompleted,
      'photoUrl': photoUrl,

      'completedAt': completedAt == null ? null : Timestamp.fromDate( completedAt!,),
      'completedByTeacherId': completedByTeacherId,
    };
  }

  DutyTaskAssignment copyWith({
    bool? isCompleted,
    String? photoUrl,
    DateTime? completedAt,
    String? completedByTeacherId,
    List<String>? teacherIds,
    List<String>? teacherNameSnapshots,
  }) {
    return DutyTaskAssignment(
      id: id,

      dutyAssignmentId: dutyAssignmentId,
      dutyTaskId: dutyTaskId,
      taskNameSnapshot: taskNameSnapshot,

      teacherIds: teacherIds ?? this.teacherIds,
      teacherNameSnapshots: teacherNameSnapshots ?? this.teacherNameSnapshots,

      isCompleted: isCompleted ?? this.isCompleted,

      photoUrl: photoUrl ?? this.photoUrl,
      completedAt: completedAt ?? this.completedAt,
      completedByTeacherId: completedByTeacherId ?? this.completedByTeacherId,
    );
  }
}