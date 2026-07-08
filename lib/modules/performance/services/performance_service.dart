import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../teachers/models/teacher.dart';
import '../models/performance.dart';
import '../utils/performance_constants.dart';

class PerformanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double scoreForSeverity(String severity, {required bool isPositive}) {
    if (isPositive) {
      return {
            'Minor': 1.0,
            'Normal': 1.0,
            'Major': 2.0,
            'Critical': 3.0,
          }[severity] ??
          1.0;
    }

    return {
          'Minor': -1.0,
          'Normal': -2.0,
          'Major': -3.0,
          'Critical': -5.0,
        }[severity] ??
        -2.0;
  }

  Stream<List<TeacherRecord>> getTeachers() {
    return _db
        .collection('teachers')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeacherRecord.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName)));
  }

  Stream<List<TeacherRecord>> fetchAllTeachers() {
    return getTeachers();
  }

  Stream<TeacherRecord?> getTeacherRecord(String teacherId) {
    return _db.collection('teachers').doc(teacherId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return TeacherRecord.fromMap(snapshot.id, snapshot.data() ?? {});
    });
  }

  Stream<List<PerformanceLog>> getPerformanceLogsForTeacher(String teacherId) {
    return _db
        .collection('performance_logs')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
          final logs = snapshot.docs
              .map((doc) => PerformanceLog.fromMap(doc.id, doc.data()))
              .toList();
          logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return logs;
        });
  }

  Stream<List<PerformanceLog>> getPerformanceLogsForTeacherInYear(
      String teacherId, int year) {
    return getPerformanceLogsForTeacher(teacherId).map((logs) {
      return logs.where((log) => log.timestamp.year == year).toList();
    });
  }

  Stream<List<WarningRecord>> getWarningsForTeacher(String teacherId) {
    return _db
        .collection('warnings')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
          final warnings = snapshot.docs
              .map((doc) => WarningRecord.fromMap(doc.id, doc.data()))
              .toList();
          warnings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return warnings;
        });
  }

  Stream<List<KpiNotification>> getNotificationsForTeacher(String teacherId) {
    return _db
        .collection('notifications')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => KpiNotification.fromMap(doc.id, doc.data()))
              .toList();
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return notifications;
        });
  }

  Stream<YearlyKpiRecord?> getYearlyKpi(String teacherId, int year) {
    return _db
        .collection('yearly_kpis')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map((doc) => YearlyKpiRecord.fromMap(doc.id, doc.data()))
          .where((record) => record.year == year)
          .toList();
      if (records.isEmpty) return null;
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records.first;
    });
  }

  Future<void> addPerformanceLog(PerformanceLog log) async {
    final logRef = _db.collection('performance_logs').doc(log.id);
    final teacherRef = _db.collection('teachers').doc(log.teacherId);

    await _db.runTransaction((transaction) async {
      final teacherSnapshot = await transaction.get(teacherRef);
      final currentScore =
          ((teacherSnapshot.data()?['currentScore'] ?? kpiBaselineScore) as num)
              .toDouble();
      final newScore = currentScore + log.amount;

      transaction.set(logRef, log.toMap());
      transaction.update(teacherRef, {'currentScore': newScore.round()});
    });

    await triggerNotifications(log);
    await triggerWarnings(log);

    // Keep the persisted yearly KPI record in sync with the latest logs so
    // "Final Score" / rating reflects every merit or deduction immediately,
    // instead of only updating when the principal manually runs the batch
    // "Calculate KPI for <year>" action.
    await _recalculateAndPersistYearlyKpi(
      log.teacherId,
      log.principalId,
      log.timestamp.year,
    );
  }

  Future<void> addWarningRecord(WarningRecord warning) async {
    await _db.collection('warnings').doc(warning.id).set(warning.toMap());
    final detail = warning.message.isNotEmpty
        ? warning.message
        : 'A warning has been added to your performance record.';
    await _createNotification(
      warning.teacherId,
      'Warning issued: ${warning.warningType}',
      detail,
      type: 'warning',
    );
  }

  Stream<List<WarningRecord>> getAllWarnings() {
    return _db.collection('warnings').snapshots().map((snapshot) {
      final warnings = snapshot.docs
          .map((doc) => WarningRecord.fromMap(doc.id, doc.data()))
          .toList();
      warnings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return warnings;
    });
  }

  Future<List<WarningRecord>> fetchAllWarningsOnce() async {
    final snapshot = await _db.collection('warnings').get();
    final warnings = snapshot.docs
        .map((doc) => WarningRecord.fromMap(doc.id, doc.data()))
        .toList();
    warnings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return warnings;
  }

  Stream<List<YearlyKpiRecord>> getYearlyKpisForYear(int year) {
    return _db
        .collection('yearly_kpis')
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map((doc) => YearlyKpiRecord.fromMap(doc.id, doc.data()))
          .toList();
      records.sort((a, b) => b.finalScore.compareTo(a.finalScore));
      return records;
    });
  }

  Future<List<YearlyKpiRecord>> fetchYearlyKpisForYearOnce(int year) async {
    final snapshot = await _db
        .collection('yearly_kpis')
        .where('year', isEqualTo: year)
        .get();
    final records = snapshot.docs
        .map((doc) => YearlyKpiRecord.fromMap(doc.id, doc.data()))
        .toList();
    records.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return records;
  }

  Future<List<TeacherRecord>> fetchAllTeachersOnce() async {
    final snapshot = await _db
        .collection('teachers')
        .where('role', isEqualTo: 'teacher')
        .get();
    final teachers = snapshot.docs
        .map((doc) => TeacherRecord.fromMap(doc.id, doc.data()))
        .toList();
    teachers.sort((a, b) => a.fullName.compareTo(b.fullName));
    return teachers;
  }

  Future<List<PerformanceLog>> fetchTeacherLogs(
    String teacherId, {
    String? severity,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final snapshot = await _db
        .collection('performance_logs')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final logs = snapshot.docs
        .map((doc) => PerformanceLog.fromMap(doc.id, doc.data()))
        .where((log) {
          if (severity != null && severity != 'All' && log.severity != severity) {
            return false;
          }
          if (category != null && category != 'All' && log.category != category) {
            return false;
          }
          if (startDate != null && log.timestamp.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && log.timestamp.isAfter(endDate)) {
            return false;
          }
          return true;
        })
        .toList();

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Future<Map<int, double>> calculateMonthlyScores(String teacherId, int year) async {
    final logs = await getPerformanceLogsForTeacherInYear(teacherId, year).first;

    final monthlyScores = <int, double>{};
    for (int month = 1; month <= 12; month++) {
      monthlyScores[month] = 0;
    }

    for (final log in logs) {
      final month = log.timestamp.month;
      monthlyScores[month] = (monthlyScores[month] ?? 0) + log.amount;
    }

    return monthlyScores;
  }

  Future<Map<int, double>> calculateMonthlyScore(String teacherId, int year) {
    return calculateMonthlyScores(teacherId, year);
  }

  Future<double> _calculateTrendFactor(
      String teacherId, int year, Map<int, double> currentMonthly) async {
    if (year <= 1) return 1.0;

    final prevMonthly = await calculateMonthlyScores(teacherId, year - 1);
    final prevActiveScores = prevMonthly.values.where((score) => score != 0).toList();
    final prevAverage = prevActiveScores.isEmpty
        ? 0.0
        : prevActiveScores.reduce((a, b) => a + b) / prevActiveScores.length;

    final currentActiveScores =
        currentMonthly.values.where((score) => score != 0).toList();
    final currentAverage = currentActiveScores.isEmpty
        ? 0.0
        : currentActiveScores.reduce((a, b) => a + b) /
            currentActiveScores.length;

    if (currentAverage > prevAverage) {
      return 1.1;
    } else if (currentAverage < prevAverage) {
      return 0.9;
    } else {
      return 1.0;
    }
  }

  String _calculateRating(double score) {
    if (score >= 85) return 'A';
    if (score >= 70) return 'B';
    if (score >= 55) return 'C';
    if (score >= 40) return 'D';
    return 'E';
  }

  Future<YearlyKpiRecord> calculateYearlyKPI(
      String teacherId, int year, String principalId) async {
    final logs = await getPerformanceLogsForTeacherInYear(teacherId, year).first;
    final monthlyScores = await calculateMonthlyScores(teacherId, year);
    final activeMonths = logs.map((log) => log.timestamp.month).toSet();
    final activeMonthlyScores = activeMonths
        .map((month) => monthlyScores[month] ?? 0.0)
        .toList();
    final average = activeMonths.isEmpty
        ? 0.0
        : activeMonthlyScores.reduce((a, b) => a + b) /
            activeMonths.length;
    final trend = await _calculateTrendFactor(teacherId, year, monthlyScores);
    final finalScore = (kpiBaselineScore + (average * trend))
        .clamp(kpiMinimumScore, kpiMaximumScore)
        .toDouble();
    final rating = _calculateRating(finalScore);

    final kpiRecord = YearlyKpiRecord(
      id: '$teacherId-$year',
      teacherId: teacherId,
      year: year,
      averageMonthlyScore: average,
      trendFactor: trend,
      finalScore: finalScore,
      rating: rating,
      status: 'Pending',
      notes:
          'Auto-calculated from ${activeMonths.length} active month(s); empty months are neutral.',
      timestamp: DateTime.now(),
    );

    return kpiRecord;
  }

  Future<void> runAllKPIForYear(int year, String principalId) async {
    final teachers = await _db
        .collection('teachers')
        .where('role', isEqualTo: 'teacher')
        .get();

    for (final teacherDoc in teachers.docs) {
      await _recalculateAndPersistYearlyKpi(teacherDoc.id, principalId, year);
    }
  }

  /// Recomputes a single teacher's yearly KPI from their current logs and
  /// writes it to `yearly_kpis`, keeping `teachers/{id}.yearlyKpi` in sync.
  /// This is the single place that persists a KPI recalculation — called
  /// both after every individual performance log (addPerformanceLog) and
  /// by the principal's manual "Calculate KPI for <year>" batch action
  /// (runAllKPIForYear), so the two paths can never drift apart.
  Future<void> _recalculateAndPersistYearlyKpi(
      String teacherId, String principalId, int year) async {
    final kpi = await calculateYearlyKPI(teacherId, year, principalId);
    await _db.collection('yearly_kpis').doc(kpi.id).set(kpi.toMap());
    await _db.collection('teachers').doc(teacherId).update({
      'yearlyKpi': kpi.finalScore.round(),
    });
  }

  Future<void> runFullKPIComputation(int year, String principalId) {
    return runAllKPIForYear(year, principalId);
  }

  Future<void> updateTeacherScore(String teacherId, double newScore) async {
    await _db.collection('teachers').doc(teacherId).update({
      'currentScore': newScore.round(),
    });
  }

  Future<void> triggerNotifications(PerformanceLog log) async {
    final teacherName = await _getTeacherName(log.teacherId);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final todayLogs = (await fetchTeacherLogs(log.teacherId))
        .where((logEntry) =>
            !logEntry.timestamp.isBefore(startOfDay) &&
            !logEntry.timestamp.isAfter(endOfDay))
        .toList();

    double dailyDeductionTotal = 0;
    for (final logEntry in todayLogs) {
      final amount = logEntry.amount;
      if (amount < 0) dailyDeductionTotal += amount;
    }

    if (dailyDeductionTotal < -30) {
      await _createNotification(
        log.teacherId,
        'Daily Safety Threshold Alert',
        'Deductions exceed -30 points today. Total: ${dailyDeductionTotal.toStringAsFixed(1)}',
        type: 'warning',
      );
    }

    if (log.severity == 'Critical' && log.amount < 0) {
      await _createNotification(
        log.teacherId,
        'CRITICAL ALERT: $teacherName',
        'A critical deduction was recorded in your performance summary.',
        type: 'warning',
      );
    }

    final teacher = await _db.collection('teachers').doc(log.teacherId).get();
    final currentScore = ((teacher.data()?['currentScore'] ?? 0) as num).toDouble();

    if (currentScore < -30) {
      await _createNotification(
        log.teacherId,
        'Score Threshold Alert: $teacherName',
        'Teacher score has fallen below -30. Current: ${currentScore.toStringAsFixed(1)}',
        type: 'warning',
      );
    }
  }

  String _warningTypeForScore(double score) {
    if (score < 50) return 'Critical Alert';
    if (score < 60) return 'Final Warning';
    if (score < 70) return 'Written Warning';
    if (score < 80) return 'Verbal Warning';
    return '';
  }

  Future<void> triggerWarnings(PerformanceLog log) async {
    final teacher = await _db.collection('teachers').doc(log.teacherId).get();
    final currentScore =
        ((teacher.data()?['currentScore'] ?? kpiBaselineScore) as num)
            .toDouble();

    final warningType = _warningTypeForScore(currentScore);
    if (warningType.isEmpty) return;

    final id = '${log.teacherId}-${DateTime.now().millisecondsSinceEpoch}';
    await addWarningRecord(WarningRecord(
      id: id,
      teacherId: log.teacherId,
      issuedBy: log.principalId,
      createdAt: DateTime.now(),
      warningType: warningType,
      reason: 'Performance score dropped to ${currentScore.toStringAsFixed(0)}',
      notes: 'Auto-generated warning based on KPI threshold',
    ));
  }

  Future<Map<String, dynamic>> getTeacherKPIDetails(String teacherId, int year) async {
    final teacher = await _db.collection('teachers').doc(teacherId).get();
    final logs = await fetchTeacherLogs(teacherId);
    final monthlyScores = await calculateMonthlyScores(teacherId, year);
    final kpiSnapshot = await _db
        .collection('yearly_kpis')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final yearlyRecords = kpiSnapshot.docs
        .map((doc) => YearlyKpiRecord.fromMap(doc.id, doc.data()))
        .where((record) => record.year == year)
        .toList();

    yearlyRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return {
      'teacher': teacher.exists
          ? TeacherRecord.fromMap(teacher.id, teacher.data() ?? {})
          : null,
      'logs': logs,
      'monthlyScores': monthlyScores,
      'yearlyKpi': yearlyRecords.isEmpty ? null : yearlyRecords.first,
    };
  }

  Future<void> seedDummyPerformanceData() async {
    final teachers = await _db
        .collection('teachers')
        .where('role', isEqualTo: 'teacher')
        .get();
    if (teachers.docs.isEmpty) return;

    final existingLogs = await _db.collection('performance_logs').limit(1).get();
    if (existingLogs.docs.isNotEmpty) return;

    final random = Random();
    final now = DateTime.now();
    final categories = ['Attendance', 'Academic', 'Conduct', 'Training'];
    final criteria = [
      'Punctuality',
      'Lesson Quality',
      'Professional Development',
      'Student Support',
    ];
    final severities = ['Minor', 'Normal', 'Major', 'Critical'];
    final scoreDeltas = <String, double>{};
    final batch = _db.batch();

    for (final teacher in teachers.docs) {
      final logCount = 10 + random.nextInt(21);
      var teacherDelta = 0.0;

      for (var index = 0; index < logCount; index++) {
        final severity = severities[random.nextInt(severities.length)];
        final isPositive = random.nextBool();
        final amount = scoreForSeverity(severity, isPositive: isPositive);
        final timestamp = DateTime(
          now.year,
          now.month - random.nextInt(12),
          1 + random.nextInt(24),
          random.nextInt(18),
          random.nextInt(60),
        );
        final logRef = _db.collection('performance_logs').doc();

        batch.set(
          logRef,
          PerformanceLog(
            id: logRef.id,
            teacherId: teacher.id,
            principalId: 'seed',
            amount: amount,
            reason: isPositive
                ? 'Seeded merit performance record'
                : 'Seeded deduction performance record',
            category: categories[random.nextInt(categories.length)],
            criterion: criteria[random.nextInt(criteria.length)],
            severity: severity,
            timestamp: timestamp,
          ).toMap(),
        );

        teacherDelta += amount;
      }

      scoreDeltas[teacher.id] = teacherDelta;
    }

    for (final teacher in teachers.docs) {
      final currentScore =
          ((teacher.data()['currentScore'] ?? kpiBaselineScore) as num)
              .toDouble();
      final delta = scoreDeltas[teacher.id] ?? 0.0;
      batch.update(
        _db.collection('teachers').doc(teacher.id),
        {'currentScore': (currentScore + delta).round()},
      );
    }

    await batch.commit();
  }

  Future<void> _createNotification(
      String teacherId, String title, String message,
      {String type = 'warning'}) async {
    await _db.collection('notifications').add({
      'teacherId': teacherId,
      'userId': teacherId,
      'title': title,
      'message': message,
      'timestamp': Timestamp.now(),
      'read': false,
      'type': type,
      'relatedId': teacherId,
    });
  }

  Future<String> _getTeacherName(String teacherId) async {
    final teacher = await _db.collection('teachers').doc(teacherId).get();
    final data = teacher.data();
    final name = data?['fullName'] ?? data?['username'];
    return (name == null || name.toString().trim().isEmpty)
        ? teacherId
        : name.toString();
  }

  // ─── Data integrity / cleanup ────────────────────────────────────────────────

  /// Deletes performance_logs, warnings, notifications, and yearly_kpis
  /// documents whose `teacherId` no longer matches any document in the
  /// `teachers` collection (e.g. a teacher account was deleted, or a
  /// leftover test/seed record referenced a teacher ID that no longer
  /// exists). This is what causes orphaned entries to show up as raw IDs
  /// (e.g. "t_sarah") instead of resolved names in the KPI leaderboard.
  ///
  /// Returns the number of documents deleted.
  Future<int> cleanupOrphanedRecords() async {
    final teachersSnapshot = await _db.collection('teachers').get();
    final validTeacherIds = teachersSnapshot.docs.map((d) => d.id).toSet();

    const collectionsToCheck = [
      'yearly_kpis',
      'performance_logs',
      'warnings',
      'notifications',
    ];

    final orphanedRefs = <DocumentReference>[];

    for (final collectionName in collectionsToCheck) {
      final snapshot = await _db.collection(collectionName).get();
      for (final doc in snapshot.docs) {
        final teacherId = doc.data()['teacherId'] as String?;
        if (teacherId == null || !validTeacherIds.contains(teacherId)) {
          orphanedRefs.add(doc.reference);
        }
      }
    }

    // Firestore batches are capped at 500 writes; chunk defensively.
    const chunkSize = 450;
    for (var i = 0; i < orphanedRefs.length; i += chunkSize) {
      final end =
          (i + chunkSize > orphanedRefs.length) ? orphanedRefs.length : i + chunkSize;
      final chunk = orphanedRefs.sublist(i, end);
      final batch = _db.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    return orphanedRefs.length;
  }
}