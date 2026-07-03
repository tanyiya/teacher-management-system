import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/notification.dart';

const _notifProjectId = 'teacher-management-syste-f8043';
const _restBase = 'https://firestore.googleapis.com/v1/projects/$_notifProjectId'
    '/databases/(default)/documents';

// Converts a Firestore REST typed value to a plain Dart value.
dynamic _fromRestVal(dynamic val) {
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
      fields.entries.map((e) => MapEntry(e.key as String, _fromRestVal(e.value))),
    );
  }
  if (v.containsKey('arrayValue')) {
    final values = (v['arrayValue'] as Map)['values'] as List? ?? [];
    return values.map(_fromRestVal).toList();
  }
  return null;
}

// Converts a plain Dart value to a Firestore REST typed field object.
Map<String, dynamic> _toRestField(dynamic value) {
  if (value is bool) return {'booleanValue': value};
  if (value is int) return {'integerValue': '$value'};
  if (value is double) return {'doubleValue': value};
  if (value is String) return {'stringValue': value};
  if (value is DateTime) return {'timestampValue': value.toUtc().toIso8601String()};
  return {'stringValue': '$value'};
}

// Writes a single notification document via REST (plain HTTPS — no gRPC needed).
Future<void> _postNotificationRest({
  required String userId,
  required String title,
  required String message,
  required String type,
  String relatedId = '',
}) async {
  final uri = Uri.parse('$_restBase/notifications');
  await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'fields': {
        'userId':    _toRestField(userId),
        'title':     _toRestField(title),
        'message':   _toRestField(message),
        'read':      _toRestField(false),
        'timestamp': _toRestField(DateTime.now()),
        'type':      _toRestField(type),
        'relatedId': _toRestField(relatedId),
      },
    }),
  ).timeout(const Duration(seconds: 10));
}

// Queries the teachers collection for a given role and returns their document IDs.
Future<List<String>> _fetchIdsByRoleRest(String role) async {
  final uri = Uri.parse('$_restBase:runQuery');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'structuredQuery': {
        'from': [{'collectionId': 'teachers'}],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'role'},
            'op': 'EQUAL',
            'value': {'stringValue': role},
          },
        },
        'select': {
          'fields': [{'fieldPath': '__name__'}],
        },
      },
    }),
  ).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) return [];
  final rows = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
  return rows
      .where((r) => r.containsKey('document'))
      .map((r) => (r['document']['name'] as String).split('/').last)
      .toList();
}

Future<List<AlertNotification>> _fetchNotificationsRest(String userId) async {
  final uri = Uri.parse('$_restBase:runQuery');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'structuredQuery': {
        'from': [{'collectionId': 'notifications'}],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'userId'},
            'op': 'EQUAL',
            'value': {'stringValue': userId},
          },
        },
      },
    }),
  ).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) return [];
  final rows = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
  final list = rows
      .where((r) => r.containsKey('document'))
      .map((r) {
        final doc = r['document'] as Map<String, dynamic>;
        final id = (doc['name'] as String).split('/').last;
        final fields = Map<String, dynamic>.fromEntries(
          ((doc['fields'] as Map?) ?? {})
              .entries
              .map((e) => MapEntry(e.key as String, _fromRestVal(e.value))),
        );
        return AlertNotification.fromMap(id, fields);
      })
      .toList();
  list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return list;
}

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Read ──────────────────────────────────────────────────────────────────

  // Wrapped in asBroadcastStream() because async* generators are
  // single-subscription by default (even though the SDK fallback below is
  // broadcast) — callers rebuild a fresh StreamBuilder around this on every
  // parent rebuild (bell badge, AlertsScreen embedded in an IndexedStack),
  // which can otherwise try to listen to the same instance twice and throw
  // "Stream has already been listened to".
  Stream<List<AlertNotification>> getNotifications(String userId) =>
      _getNotificationsImpl(userId).asBroadcastStream();

  Stream<List<AlertNotification>> _getNotificationsImpl(String userId) async* {
    // REST first — works on Android where gRPC is blocked.
    try {
      final list = await _fetchNotificationsRest(userId);
      if (list.isNotEmpty) {
        yield list;
        return;
      }
    } catch (_) {}
    // Fallback: real-time stream (works on Chrome / when gRPC is available).
    yield* _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => AlertNotification.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  // ── Write (all writes use REST so they work on Android without gRPC) ───────

  Future<void> send({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    String relatedId = '',
  }) async {
    await _postNotificationRest(
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
    );
  }

  /// Sends to all teachers with role == 'teacher'.
  Future<void> sendToAllTeachers({
    required String title,
    required String message,
    String type = 'broadcast',
    String relatedId = '',
  }) async {
    final ids = await _fetchIdsByRoleRest('teacher');
    for (final id in ids) {
      await _postNotificationRest(
          userId: id, title: title, message: message, type: type, relatedId: relatedId);
    }
  }

  /// Sends to all users with role == 'principal'.
  Future<void> sendToAdmins({
    required String title,
    required String message,
    String type = 'admin',
    String relatedId = '',
  }) async {
    final ids = await _fetchIdsByRoleRest('principal');
    for (final id in ids) {
      await _postNotificationRest(
          userId: id, title: title, message: message, type: type, relatedId: relatedId);
    }
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    // Filter read==false client-side to avoid a composite index requirement.
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    final unread = snap.docs.where((d) => d.data()['read'] == false).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }
}
