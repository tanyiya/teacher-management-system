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
}

class WarningRecord {
  final String id;
  final String teacherId;
  final String issuedBy;
  final DateTime issueDate;
  final String message;
  final String severity;

  WarningRecord({
    required this.id,
    required this.teacherId,
    required this.issuedBy,
    required this.issueDate,
    required this.message,
    required this.severity,
  });

  factory WarningRecord.fromMap(String id, Map<String, dynamic> data) {
    return WarningRecord(
      id: id,
      teacherId: data['teacherId'] ?? '',
      issuedBy: data['issuedBy'] ?? '',
      issueDate: (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      message: data['message'] ?? '',
      severity: data['severity'] ?? 'Verbal',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'issuedBy': issuedBy,
      'issueDate': Timestamp.fromDate(issueDate),
      'message': message,
      'severity': severity,
    };
  }
}
