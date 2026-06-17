import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/teacher.dart';
import '../models/change_request.dart';
import '../../../core/services/notification_service.dart';

const _projectId = 'teacher-management-syste-f8043';

// Converts a Firestore REST field value (typed wrapper) to a plain Dart value.
dynamic _fromRestValue(dynamic val) {
  if (val is! Map) return val;
  final v = Map<String, dynamic>.from(val);
  if (v.containsKey('stringValue')) return v['stringValue'];
  if (v.containsKey('integerValue')) return int.tryParse(v['integerValue'].toString()) ?? 0;
  if (v.containsKey('doubleValue')) return (v['doubleValue'] as num).toDouble();
  if (v.containsKey('booleanValue')) return v['booleanValue'];
  if (v.containsKey('timestampValue')) return v['timestampValue'];
  if (v.containsKey('nullValue')) return null;
  if (v.containsKey('mapValue')) {
    final fields = (v['mapValue'] as Map)['fields'] as Map? ?? {};
    return Map<String, dynamic>.fromEntries(
      fields.entries.map((e) => MapEntry(e.key as String, _fromRestValue(e.value))),
    );
  }
  if (v.containsKey('arrayValue')) {
    final values = (v['arrayValue'] as Map)['values'] as List? ?? [];
    return values.map(_fromRestValue).toList();
  }
  return null;
}

Future<List<TeacherRecord>> _fetchTeachersRest() async {
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_projectId'
    '/databases/(default)/documents/teachers',
  );
  final res = await http.get(uri).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) return [];
  final body = json.decode(res.body) as Map<String, dynamic>;
  final docs = body['documents'] as List? ?? [];
  return docs.map((doc) {
    final id = (doc['name'] as String).split('/').last;
    final fields = Map<String, dynamic>.fromEntries(
      ((doc['fields'] as Map?) ?? {})
          .entries
          .map((e) => MapEntry(e.key as String, _fromRestValue(e.value))),
    );
    return TeacherRecord.fromMap(id, fields);
  }).toList();
}

const _docLabels = {
  'myKad': 'MyKad (IC)',
  'passportPhoto': 'Passport Photo',
  'resume': 'Resume / CV',
  'academicCertificates': 'Academic Certificates',
  'medicalReport': 'Medical Report',
  'bankStatement': 'Bank Statement',
};

class TeacherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notif = NotificationService();

  Future<TeacherRecord?> _fetchTeacherRest(String id) async {
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId'
      '/databases/(default)/documents/teachers/$id',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (!body.containsKey('fields')) return null;
    final fields = Map<String, dynamic>.fromEntries(
      ((body['fields'] as Map?) ?? {})
          .entries
          .map((e) => MapEntry(e.key as String, _fromRestValue(e.value))),
    );
    return TeacherRecord.fromMap(id, fields);
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  Stream<List<TeacherRecord>> getTeachers() async* {
    // Try REST first (plain HTTPS — works even when gRPC is blocked on Android).
    // If it returns data, yield it and return so the Firestore SDK snapshots()
    // stream is never started — this prevents stale local cache from
    // overwriting fresh server data.
    try {
      final list = await _fetchTeachersRest();
      if (list.isNotEmpty) {
        yield list;
        return;
      }
    } catch (_) {}
    // Fallback: real-time stream for environments where gRPC works (e.g. Chrome).
    yield* _db.collection('teachers').snapshots().map(
          (s) => s.docs.map((d) => TeacherRecord.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<TeacherRecord?> getTeacherStream(String id) async* {
    // REST first — bypasses gRPC/local-cache so we always show server data.
    try {
      final record = await _fetchTeacherRest(id);
      if (record != null) {
        yield record;
        return;
      }
    } catch (_) {}
    // Fallback: real-time stream for environments where gRPC works (e.g. Chrome).
    yield* _db.collection('teachers').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TeacherRecord.fromMap(doc.id, doc.data()!);
    });
  }

  Future<TeacherRecord?> getTeacherById(String id) async {
    try {
      final record = await _fetchTeacherRest(id);
      if (record != null) return record;
    } catch (_) {}
    final doc = await _db.collection('teachers').doc(id).get();
    if (!doc.exists) return null;
    return TeacherRecord.fromMap(doc.id, doc.data()!);
  }

  // ── Teacher profile mutations ──────────────────────────────────────────────

  Future<void> updateTeacher(TeacherRecord teacher) async {
    await _db.collection('teachers').doc(teacher.id).set(teacher.toMap());
  }

  /// Only updates the fields teachers are allowed to change themselves.
  Future<void> updateTeacherProfile(String id, Map<String, dynamic> fields) async {
    const allowed = {
      'phoneNumber', 'email', 'address', 'maritalStatus',
      'emergencyContactName', 'emergencyContactNumber',
    };
    final safe = Map.fromEntries(
      fields.entries.where((e) => allowed.contains(e.key)),
    );
    if (safe.isNotEmpty) {
      // set+merge instead of update() so the write succeeds even when the
      // document is absent from the Firestore SDK's local cache (which is
      // always the case here because we use REST for reads, not the SDK).
      await _db.collection('teachers').doc(id).set(safe, SetOptions(merge: true));
    }
  }

  /// Admin can update any field on a teacher document.
  Future<void> adminUpdateTeacher(String id, Map<String, dynamic> fields) async {
    await _db.collection('teachers').doc(id).set(fields, SetOptions(merge: true));
  }

  // ── Document management ───────────────────────────────────────────────────

  // Writes nested document sub-fields via Firestore REST PATCH + updateMask.
  // This avoids gRPC (which is blocked on some Android devices) and avoids
  // the SDK update() dot-notation path that requires local cache presence.
  Future<void> _updateDocumentStatusRest(
    String teacherId,
    String docKey,
    String status, {
    String rejectionReason = '',
    String url = '',
    List<String> ocrWarnings = const [],
  }) async {
    final now = DateTime.now().toIso8601String();

    final maskFields = <String>[
      'documents.$docKey.status',
      'documents.$docKey.rejectionReason',
      'documents.$docKey.ocrWarnings',
    ];
    if (url.isNotEmpty) {
      maskFields.add('documents.$docKey.url');
      maskFields.add('documents.$docKey.uploadedAt');
    }
    if (status == 'verified') {
      maskFields.add('documents.$docKey.verifiedAt');
    }

    final docFields = <String, dynamic>{
      'status': {'stringValue': status},
      'rejectionReason': {'stringValue': rejectionReason},
      'ocrWarnings': {
        'arrayValue': {
          'values': ocrWarnings.map((w) => {'stringValue': w}).toList(),
        },
      },
    };
    if (url.isNotEmpty) {
      docFields['url'] = {'stringValue': url};
      docFields['uploadedAt'] = {'stringValue': now};
    }
    if (status == 'verified') {
      docFields['verifiedAt'] = {'stringValue': now};
    }

    final queryString =
        maskFields.map((f) => 'updateMask.fieldPaths=$f').join('&');
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId'
      '/databases/(default)/documents/teachers/$teacherId?$queryString',
    );
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fields': {
          'documents': {
            'mapValue': {
              'fields': {
                docKey: {'mapValue': {'fields': docFields}},
              },
            },
          },
        },
      }),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('updateDocumentStatus REST ${res.statusCode}');
    }
  }

  Future<void> updateDocumentStatus(
    String teacherId,
    String docKey,
    String status, {
    String rejectionReason = '',
    String url = '',
    List<String> ocrWarnings = const [],
  }) async {
    // Try REST first — works on Android where gRPC is blocked.
    try {
      await _updateDocumentStatusRest(
        teacherId, docKey, status,
        rejectionReason: rejectionReason,
        url: url,
        ocrWarnings: ocrWarnings,
      );
    } catch (_) {
      // Fallback: SDK dot-notation update (works on Chrome / when gRPC available).
      final now = DateTime.now().toIso8601String();
      final data = <String, dynamic>{
        'documents.$docKey.status': status,
        'documents.$docKey.rejectionReason': rejectionReason,
        'documents.$docKey.ocrWarnings': ocrWarnings,
      };
      if (url.isNotEmpty) {
        data['documents.$docKey.url'] = url;
        data['documents.$docKey.uploadedAt'] = now;
      }
      if (status == 'verified') {
        data['documents.$docKey.verifiedAt'] = now;
      }
      await _db.collection('teachers').doc(teacherId).update(data);
    }
    // Notify teacher of document verification result.
    final label = _docLabels[docKey] ?? docKey;
    if (status == 'verified') {
      await _notif.send(
        userId: teacherId,
        title: 'Document Verified',
        message: 'Your $label has been verified.',
        type: 'document_verified',
      );
    } else if (status == 'rejected') {
      await _notif.send(
        userId: teacherId,
        title: 'Document Rejected',
        message: 'Your $label was rejected.'
            '${rejectionReason.isNotEmpty ? ' Reason: $rejectionReason' : ''}',
        type: 'document_rejected',
      );
    }
  }

  // ── Verification status ───────────────────────────────────────────────────

  Future<void> updateVerificationStatus(
    String teacherId,
    String status, {
    String rejectionReason = '',
  }) async {
    await _db.collection('teachers').doc(teacherId).set({
      'verificationStatus': status,
      'verificationRejectionReason': rejectionReason,
    }, SetOptions(merge: true));
    if (status == 'approved') {
      await _notif.send(
        userId: teacherId,
        title: 'Record Approved',
        message: 'Your teacher record has been approved.',
        type: 'record_approved',
      );
    } else if (status == 'rejected') {
      await _notif.send(
        userId: teacherId,
        title: 'Record Rejected',
        message: 'Your record was rejected.'
            '${rejectionReason.isNotEmpty ? ' Reason: $rejectionReason' : ''}',
        type: 'record_rejected',
      );
    }
  }

  // ── Change requests ───────────────────────────────────────────────────────

  Future<void> submitChangeRequest(ChangeRequest request) async {
    await _db.collection('change_requests').doc(request.id).set(request.toMap());
    // Notify all principals that a change request is pending review.
    await _notif.sendToAdmins(
      title: 'New Change Request',
      message: '${request.teacherName} requested a change to "${request.fieldLabel}".',
      type: 'change_request',
    );
  }

  Stream<List<ChangeRequest>> getChangeRequestsForTeacher(String teacherId) {
    return _db
        .collection('change_requests')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChangeRequest.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<ChangeRequest>> getAllChangeRequests() {
    return _db
        .collection('change_requests')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChangeRequest.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> reviewChangeRequest(
    String requestId,
    String teacherId,
    String field,
    String newValue,
    bool approved, {
    String rejectionReason = '',
    String reviewedBy = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.collection('change_requests').doc(requestId).update({
      'status': approved ? 'approved' : 'rejected',
      'rejectionReason': rejectionReason,
      'reviewedAt': now,
      'reviewedBy': reviewedBy,
    });
    if (approved) {
      await _db.collection('teachers').doc(teacherId).update({field: newValue});
    }
    // Notify the teacher of the review outcome.
    if (approved) {
      await _notif.send(
        userId: teacherId,
        title: 'Change Request Approved',
        message: 'Your request to change "$field" has been approved.',
        type: 'change_approved',
      );
    } else {
      await _notif.send(
        userId: teacherId,
        title: 'Change Request Rejected',
        message: 'Your request to change "$field" was rejected.'
            '${rejectionReason.isNotEmpty ? ' Reason: $rejectionReason' : ''}',
        type: 'change_rejected',
      );
    }
  }
}
