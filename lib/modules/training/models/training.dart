import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String photoUrl;
  final List<Map<String, String>> attachments;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;
  final String fontStyle;
  final bool isTraining;
  final String? trainingTitle;
  final String? trainingDescription;
  final int? maxTrainees;
  final String? type;
  final String enrollmentMode;
  final List<String> traineeIds;

  TrainingPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.photoUrl,
    this.attachments = const [],
    required this.likes,
    required this.commentsCount,
    required this.createdAt,
    required this.fontStyle,
    required this.isTraining,
    this.trainingTitle,
    this.trainingDescription,
    this.maxTrainees,
    this.type,
    this.enrollmentMode = 'open_volunteer',
    required this.traineeIds,
  });

  int get seatsTaken => traineeIds.length;
  int? get remainingSeats => maxTrainees == null
      ? null
      : (maxTrainees! - seatsTaken).clamp(0, maxTrainees!);
  bool get isFull => maxTrainees != null && seatsTaken >= maxTrainees!;
  bool get isOpenVolunteer => enrollmentMode == 'open_volunteer';

  factory TrainingPost.fromMap(String id, Map<String, dynamic> data) {
    return TrainingPost(
      id: id,
      authorId: _stringValue(data['authorId']),
      authorName: _stringValue(data['authorName']),
      authorRole: _stringValue(data['authorRole'], fallback: 'teacher'),
      content: _stringValue(data['content']),
      photoUrl: _stringValue(data['photoUrl']),
      attachments: _parseAttachments(data['attachments']),
      likes: _stringListValue(data['likes']),
      commentsCount: data['commentsCount']?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fontStyle: _stringValue(data['fontStyle'], fallback: 'sans'),
      isTraining: _boolValue(data['isTraining']),
      trainingTitle: _nullableStringValue(data['trainingTitle']),
      trainingDescription: _nullableStringValue(data['trainingDescription']),
      maxTrainees: data['maxTrainees']?.toInt(),
      type: _nullableStringValue(data['type']),
      enrollmentMode: _stringValue(
        data['enrollmentMode'] ?? data['type'],
        fallback: 'open_volunteer',
      ),
      traineeIds: _stringListValue(data['traineeIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'content': content,
      'photoUrl': photoUrl,
      'attachments': attachments,
      'likes': likes,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'fontStyle': fontStyle,
      'isTraining': isTraining,
      'trainingTitle': trainingTitle,
      'trainingDescription': trainingDescription,
      'maxTrainees': maxTrainees,
      'type': type,
      'enrollmentMode': enrollmentMode,
      'traineeIds': traineeIds,
    };
  }
}

class TrainingComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String text;
  final DateTime createdAt;

  TrainingComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.text,
    required this.createdAt,
  });

  factory TrainingComment.fromMap(String id, Map<String, dynamic> data) {
    return TrainingComment(
      id: id,
      postId: _stringValue(data['postId']),
      authorId: _stringValue(data['authorId']),
      authorName: _stringValue(data['authorName']),
      authorRole: _stringValue(data['authorRole'], fallback: 'teacher'),
      text: _stringValue(data['text']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class TrainingApplication {
  final String id;
  final String postId;
  final String trainingTitle;
  final String teacherId;
  final String teacherName;
  final String status;
  final DateTime createdAt;

  TrainingApplication({
    required this.id,
    required this.postId,
    required this.trainingTitle,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    required this.createdAt,
  });

  factory TrainingApplication.fromMap(String id, Map<String, dynamic> data) {
    return TrainingApplication(
      id: id,
      postId: _stringValue(data['postId']),
      trainingTitle: _stringValue(data['trainingTitle']),
      teacherId: _stringValue(data['teacherId']),
      teacherName: _stringValue(data['teacherName']),
      status: _stringValue(data['status'], fallback: 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'trainingTitle': trainingTitle,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

String? _nullableStringValue(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

List<String> _stringListValue(Object? value) {
  if (value is Iterable) {
    return value.map((item) => _stringValue(item)).toList();
  }
  return const [];
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

List<Map<String, String>> _parseAttachments(dynamic data) {
  if (data is List) {
    return data.map((item) {
      if (item is Map) {
        return {
          'url': _stringValue(item['url']),
          'name': _stringValue(item['name']),
          'type': _stringValue(item['type']),
        };
      }
      return <String, String>{};
    }).where((map) => map.isNotEmpty).toList();
  }
  return const [];
}

class LocalAttachment {
  final String path;
  final String name;
  final bool isImage;
  
  LocalAttachment({
    required this.path, 
    required this.name, 
    required this.isImage,
  });
}
