import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/duty_location.dart';

class DutyLocationService {
  final _col = FirebaseFirestore.instance.collection('duty_locations');

  // Live stream of all locations
  Stream<List<DutyLocation>> getLocations() {
    return _col.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DutyLocation.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<DutyLocation>> getActiveLocations() {
  return _col
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return DutyLocation.fromMap(doc.id, doc.data());
        }).toList();
      });
  }

  // Get location by ID
  Future<DutyLocation?> getLocationById(String id) async {
    final doc = await _col.doc(id).get();

    if (!doc.exists) return null;

    return DutyLocation.fromMap(doc.id, doc.data()!);
  }

  // Add new location
  Future<String> addLocation(DutyLocation location) async {
    final doc = await _col.add(location.toMap());
    return doc.id;
  }

  // Update location
  Future<void> updateLocation(DutyLocation location) async {
    await _col.doc(location.id).update(location.toMap());
  }

  // Update location status
  Future<void> updateActiveStatus(String id, bool isActive) async {
    await _col.doc(id).update({'isActive': isActive});
  }

  // Delete location
  Future<void> deleteLocation(String id) async {
    await _col.doc(id).delete();
  }
}