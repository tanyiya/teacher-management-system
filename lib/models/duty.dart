import 'package:cloud_firestore/cloud_firestore.dart';

class DutyLocation {
  final String id;
  final String name;
  final String description;

  DutyLocation({required this.id, required this.name, required this.description});

  factory DutyLocation.fromMap(String id, Map<String, dynamic> data) {
    return DutyLocation(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class DutyTask {
  final String id;
  final String name;
  final String timeStart;
  final String timeEnd;
  final String frequency;
  final List<String> locations;
  final int minPeople;
  final List<String> checklistTemplates;
  final String? genderRequirement;
  final int? dayOfWeek;
  final int? dayOfMonth;

  DutyTask({
    required this.id,
    required this.name,
    required this.timeStart,
    required this.timeEnd,
    required this.frequency,
    required this.locations,
    required this.minPeople,
    required this.checklistTemplates,
    this.genderRequirement,
    this.dayOfWeek,
    this.dayOfMonth,
  });

  factory DutyTask.fromMap(String id, Map<String, dynamic> data) {
    return DutyTask(
      id: id,
      name: data['name'] ?? '',
      timeStart: data['timeStart'] ?? '',
      timeEnd: data['timeEnd'] ?? '',
      frequency: data['frequency'] ?? 'Daily',
      locations: List<String>.from(data['locations'] ?? []),
      minPeople: data['minPeople']?.toInt() ?? 1,
      checklistTemplates: List<String>.from(data['checklistTemplates'] ?? []),
      genderRequirement: data['genderRequirement'],
      dayOfWeek: data['dayOfWeek']?.toInt(),
      dayOfMonth: data['dayOfMonth']?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'frequency': frequency,
      'locations': locations,
      'minPeople': minPeople,
      'checklistTemplates': checklistTemplates,
      'genderRequirement': genderRequirement,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
    };
  }
}

class DutyChecklistItem {
  final String id;
  final String description;
  final bool isCompleted;
  final String? photoUrl;
  final DateTime? completedAt;

  DutyChecklistItem({
    required this.id,
    required this.description,
    required this.isCompleted,
    this.photoUrl,
    this.completedAt,
  });

  factory DutyChecklistItem.fromMap(Map<String, dynamic> data) {
    return DutyChecklistItem(
      id: data['id'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      photoUrl: data['photoUrl'],
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'isCompleted': isCompleted,
      'photoUrl': photoUrl,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

class DutyAssignment {
  final String id;
  final String taskId;
  final String taskName;
  final String date;
  final String locationId;
  final String locationName;
  final List<String> teacherIds;
  final String status;
  final String timeStart;
  final String timeEnd;
  final bool isReplacement;
  final List<DutyChecklistItem> checklist;

  DutyAssignment({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.date,
    required this.locationId,
    required this.locationName,
    required this.teacherIds,
    required this.status,
    required this.timeStart,
    required this.timeEnd,
    required this.isReplacement,
    required this.checklist,
  });

  factory DutyAssignment.fromMap(String id, Map<String, dynamic> data) {
    return DutyAssignment(
      id: id,
      taskId: data['taskId'] ?? '',
      taskName: data['taskName'] ?? '',
      date: data['date'] ?? '',
      locationId: data['locationId'] ?? '',
      locationName: data['locationName'] ?? '',
      teacherIds: List<String>.from(data['teacherIds'] ?? []),
      status: data['status'] ?? 'pending',
      timeStart: data['timeStart'] ?? '',
      timeEnd: data['timeEnd'] ?? '',
      isReplacement: data['isReplacement'] ?? false,
      checklist: (data['checklist'] as List<dynamic>? ?? [])
          .map((item) => DutyChecklistItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskName': taskName,
      'date': date,
      'locationId': locationId,
      'locationName': locationName,
      'teacherIds': teacherIds,
      'status': status,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'isReplacement': isReplacement,
      'checklist': checklist.map((c) => c.toMap()).toList(),
    };
  }
}

class DutySwap {
  final String id;
  final String assignmentId;
  final String fromTeacherId;
  final String toTeacherId;
  final String status;
  final DateTime timestamp;
  final String requestedBy;

  DutySwap({
    required this.id,
    required this.assignmentId,
    required this.fromTeacherId,
    required this.toTeacherId,
    required this.status,
    required this.timestamp,
    required this.requestedBy,
  });

  factory DutySwap.fromMap(String id, Map<String, dynamic> data) {
    return DutySwap(
      id: id,
      assignmentId: data['assignmentId'] ?? '',
      fromTeacherId: data['fromTeacherId'] ?? '',
      toTeacherId: data['toTeacherId'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      requestedBy: data['requestedBy'] ?? 'teacher',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'fromTeacherId': fromTeacherId,
      'toTeacherId': toTeacherId,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'requestedBy': requestedBy,
    };
  }
}
