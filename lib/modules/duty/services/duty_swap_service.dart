import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/duty_swap.dart';

class DutySwapService {
  final _col = FirebaseFirestore.instance.collection('duty_swaps');

  // Live stream of all swaps
  Stream<List<DutySwap>> getSwaps() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutySwap.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Live stream of pending swaps
  Stream<List<DutySwap>> getPendingSwaps() {
    return _col
        .where('status', isEqualTo: DutySwapStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DutySwap.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Swaps requested by a user
  Stream<List<DutySwap>> getSwapsByRequester(String userId) {
    return _col
        .where('requestedById', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DutySwap.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Swaps involving a teacher
  // (Either current teacher or replacement teacher)
  Stream<List<DutySwap>> getSwapsByTeacher(String teacherId) {
    return _col
        .where(
          Filter.or(
            Filter('currentTeacherId', isEqualTo: teacherId),
            Filter('replacementTeacherId', isEqualTo: teacherId),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DutySwap.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Get swap by ID
  Future<DutySwap?> getSwapById(String id) async {
    final doc = await _col.doc(id).get();

    if (!doc.exists) return null;

    return DutySwap.fromMap(doc.id, doc.data()!);
  }

  // Create swap request
  Future<String> addSwap(DutySwap swap) async {
    final doc = await _col.add(swap.toMap());
    return doc.id;
  }

  // Update swap
  Future<void> updateSwap(DutySwap swap) async {
    await _col.doc(swap.id).update(swap.toMap());
  }

  // Approve swap
  Future<void> approveSwap(String id) async {
    await _col.doc(id).update({
      'status': DutySwapStatus.approved.name,
      'respondedAt': Timestamp.now(),
    });
  }

  // Reject swap
  Future<void> rejectSwap(String id) async {
    await _col.doc(id).update({
      'status': DutySwapStatus.rejected.name,
      'respondedAt': Timestamp.now(),
    });
  }

  // Cancel swap
  Future<void> cancelSwap(String id) async {
    await _col.doc(id).update({
      'status': DutySwapStatus.cancelled.name,
      'respondedAt': Timestamp.now(),
    });
  }

  // Delete swap
  Future<void> deleteSwap(String id) async {
    await _col.doc(id).delete();
  }
}