import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String photoUrl;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;
  final String fontStyle;
  final bool isTraining;
  final String? trainingTitle;
  final String? trainingDescription;
  final int? maxTrainees;
  final String? type;
  final List<String> traineeIds;

  TrainingPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.photoUrl,
    required this.likes,
    required this.commentsCount,
    required this.createdAt,
    required this.fontStyle,
    required this.isTraining,
    this.trainingTitle,
    this.trainingDescription,
    this.maxTrainees,
    this.type,
    required this.traineeIds,
  });

  factory TrainingPost.fromMap(String id, Map<String, dynamic> data) {
    return TrainingPost(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? 'teacher',
      content: data['content'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount']?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fontStyle: data['fontStyle'] ?? 'sans',
      isTraining: data['isTraining'] ?? false,
      trainingTitle: data['trainingTitle'],
      trainingDescription: data['trainingDescription'],
      maxTrainees: data['maxTrainees']?.toInt(),
      type: data['type'],
      traineeIds: List<String>.from(data['traineeIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'content': content,
      'photoUrl': photoUrl,
      'likes': likes,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'fontStyle': fontStyle,
      'isTraining': isTraining,
      'trainingTitle': trainingTitle,
      'trainingDescription': trainingDescription,
      'maxTrainees': maxTrainees,
      'type': type,
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
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? 'teacher',
      text: data['text'] ?? '',
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
      postId: data['postId'] ?? '',
      trainingTitle: data['trainingTitle'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      status: data['status'] ?? 'pending',
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
