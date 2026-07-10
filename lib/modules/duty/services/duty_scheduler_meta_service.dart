import 'package:cloud_firestore/cloud_firestore.dart';

/// Single-document store for the auto-scheduler's run state:
///  - `lastCheckedAt`: when the 7-day lookahead was last (re)generated, so
///    opening the schedule screen doesn't redo the work every single time
///    -- once per day is enough unless something forces a re-check.
///  - `rotationCursor`: where the round-robin teacher rotation left off,
///    so it keeps advancing across runs instead of always starting back
///    at teacher #0 (which would load the first few teachers far more
///    than everyone else).
class DutySchedulerMetaService {
  final _doc =
      FirebaseFirestore.instance.collection('duty_scheduler_meta').doc('state');

  Future<DateTime?> getLastCheckedAt() async {
    final snap = await _doc.get();
    final ts = snap.data()?['lastCheckedAt'] as Timestamp?;
    return ts?.toDate();
  }

  Future<int> getRotationCursor() async {
    final snap = await _doc.get();
    return (snap.data()?['rotationCursor'] as num?)?.toInt() ?? 0;
  }

  Future<void> saveState({
    required DateTime lastCheckedAt,
    required int rotationCursor,
  }) async {
    await _doc.set({
      'lastCheckedAt': Timestamp.fromDate(lastCheckedAt),
      'rotationCursor': rotationCursor,
    }, SetOptions(merge: true));
  }
}