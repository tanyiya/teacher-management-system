import 'package:cloud_firestore/cloud_firestore.dart';

class PerformanceLog {
  final String id;
  final String teacherId;
  final String principalId;
  final double amount;
  final String reason;
  final String category;
  final String criterion;
  final String severity;
  final DateTime timestamp;

  PerformanceLog({
    required this.id,
    required this.teacherId,
    required this.principalId,
    required this.amount,
    required this.reason,
    required this.category,
    required this.criterion,
    required this.severity,
    required this.timestamp,
  });

  factory PerformanceLog.fromMap(String id, Map<String, dynamic> data) {
    return PerformanceLog(
      id: id,
      teacherId: data['teacherId'] ?? '',
      principalId: data['principalId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      reason: data['reason'] ?? '',
      category: data['category'] ?? '',
      criterion: data['criterion'] ?? '',
      severity: data['severity'] ?? 'Normal',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PerformanceLog.fromJson(String id, Map<String, dynamic> data) {
    return PerformanceLog.fromMap(id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'principalId': principalId,
      'amount': amount,
      'reason': reason,
      'category': category,
      'criterion': criterion,
      'severity': severity,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

class WarningRecord {
  final String id;
  final String teacherId;
  final String issuedBy;
  final DateTime createdAt;
  final String warningType;
  final String reason;
  final String notes;

  WarningRecord({
    required this.id,
    required this.teacherId,
    required this.issuedBy,
    required this.createdAt,
    required this.warningType,
    required this.reason,
    required this.notes,
  });

  String get message => reason.isNotEmpty ? reason : notes;
  String get severity => warningType;
  DateTime get issueDate => createdAt;

  factory WarningRecord.fromMap(String id, Map<String, dynamic> data) {
    return WarningRecord(
      id: id,
      teacherId: data['teacherId'] ?? '',
      issuedBy: data['issuedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      warningType: data['warningType'] ?? data['severity'] ?? 'Verbal Warning',
      reason: data['reason'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  factory WarningRecord.fromJson(String id, Map<String, dynamic> data) {
    return WarningRecord.fromMap(id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'issuedBy': issuedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'warningType': warningType,
      'reason': reason,
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

class KpiNotification {
  final String id;
  final String teacherId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime timestamp;

  KpiNotification({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  factory KpiNotification.fromMap(String id, Map<String, dynamic> data) {
    return KpiNotification(
      id: id,
      teacherId: data['teacherId'] ?? data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['read'] == true || data['isRead'] == true,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory KpiNotification.fromJson(String id, Map<String, dynamic> data) {
    return KpiNotification.fromMap(id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'userId': teacherId,
      'title': title,
      'message': message,
      'read': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

class YearlyKpiRecord {
  final String id;
  final String teacherId;
  final int year;
  final double averageMonthlyScore;
  final double trendFactor;
  final double finalScore;
  final String rating;
  final String status;
  final String notes;
  final DateTime timestamp;

  YearlyKpiRecord({
    required this.id,
    required this.teacherId,
    required this.year,
    required this.averageMonthlyScore,
    required this.trendFactor,
    required this.finalScore,
    required this.rating,
    required this.status,
    required this.notes,
    required this.timestamp,
  });

  factory YearlyKpiRecord.fromMap(String id, Map<String, dynamic> data) {
    return YearlyKpiRecord(
      id: id,
      teacherId: data['teacherId'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      averageMonthlyScore: (data['averageMonthlyScore'] ?? 0.0).toDouble(),
      trendFactor: (data['trendFactor'] ?? 1.0).toDouble(),
      finalScore: (data['finalScore'] ?? 0.0).toDouble(),
      rating: data['rating'] ?? 'C',
      status: data['status'] ?? 'Pending',
      notes: data['notes'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory YearlyKpiRecord.fromJson(String id, Map<String, dynamic> data) {
    return YearlyKpiRecord.fromMap(id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'year': year,
      'averageMonthlyScore': averageMonthlyScore,
      'trendFactor': trendFactor,
      'finalScore': finalScore,
      'rating': rating,
      'status': status,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
