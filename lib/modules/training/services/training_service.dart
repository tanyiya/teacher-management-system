import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../../core/services/cloudinary_service.dart';

import '../../teachers/models/teacher.dart';
import '../models/training.dart';

class TrainingService {
  TrainingService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('training_posts');
  CollectionReference<Map<String, dynamic>> get _applications =>
      _db.collection('trainingApplications');
  CollectionReference<Map<String, dynamic>> get _teachers =>
      _db.collection('teachers');

  Future<String> createPost(TrainingPost post) async {
    final doc = post.id.isEmpty ? _posts.doc() : _posts.doc(post.id);
    await doc.set(post.toMap());
    return doc.id;
  }

  Future<String> uploadImageToStorage(
    XFile image, {
    required String authorId,
    String folder = 'training_posts',
  }) async {
    final extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = '$timestamp.$extension';
    final bytes = await image.readAsBytes();
    try {
      final cloudFolder = '$folder/$authorId';
      final url = await CloudinaryService.uploadFile(bytes, filename, folder: cloudFolder);
      if (url != null && url.isNotEmpty) {
        try {
          print('[TrainingService][uploadImageToStorage] uploaded to Cloudinary folder: $cloudFolder');
          print('[TrainingService][uploadImageToStorage] secureUrl: $url');
        } catch (_) {}
        return url;
      }
      throw Exception('Cloudinary upload failed');
    } catch (e, s) {
      try {
        print('[TrainingService][uploadImageToStorage] error: $e');
        print(s);
      } catch (_) {}
      rethrow;
    }
  }

  /// Convenience: accept a local [File] and upload it. Returns public download URL.
  Future<String> uploadFileToStorage(
    File imageFile, {
    required String authorId,
    String folder = 'training_posts',
  }) async {
    final extension = imageFile.path.contains('.')
        ? imageFile.path.split('.').last.toLowerCase()
        : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = '$timestamp.$extension';
    final bytes = await imageFile.readAsBytes();
    try {
      final cloudFolder = '$folder/$authorId';
      final url = await CloudinaryService.uploadFile(bytes, filename, folder: cloudFolder);
      if (url != null && url.isNotEmpty) {
        try {
          print('[TrainingService][uploadFileToStorage] uploaded to Cloudinary folder: $cloudFolder');
          print('[TrainingService][uploadFileToStorage] secureUrl: $url');
        } catch (_) {}
        return url;
      }
      throw Exception('Cloudinary upload failed');
    } catch (e, s) {
      try {
        print('[TrainingService][uploadFileToStorage] error: $e');
        print(s);
      } catch (_) {}
      rethrow;
    }
  }

  // _mimeTypeForExtension removed — Cloudinary handles content types.

  /// Open a URL in external browser. Returns true if opened.
  Future<bool> openUrl(String url) async {
    var uriString = url.trim();
    if (!uriString.startsWith(RegExp(r'https?:\/\/'))) {
      uriString = 'https://$uriString';
    }
    final uri = Uri.tryParse(uriString);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Stream<List<TrainingPost>> streamPosts({bool trainingOnly = false}) {
    Query<Map<String, dynamic>> query =
        _posts.orderBy('createdAt', descending: true);
    if (trainingOnly) {
      query = query.where('isTraining', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => TrainingPost.fromMap(doc.id, doc.data()))
          .toList();
      try {
        print('[TrainingService] streamPosts -> received ${posts.length} posts');
      } catch (_) {}
      return posts;
    });
  }

  Stream<List<TrainingPost>> getTrainingPosts() => streamPosts();

  Stream<List<TrainingPost>> searchPosts(String query) {
    final normalized = query.trim().toLowerCase();
    return streamPosts().map((posts) {
      if (normalized.isEmpty) return posts;
      return posts.where((post) {
        return post.content.toLowerCase().contains(normalized) ||
            post.authorName.toLowerCase().contains(normalized) ||
            (post.trainingTitle ?? '').toLowerCase().contains(normalized);
      }).toList();
    });
  }



  Future<void> toggleLike(String postId, String userId) async {
    final ref = _posts.doc(postId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
      transaction.update(ref, {
        'likes': likes.contains(userId)
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String authorRole,
    required String text,
  }) async {
    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc();
    final comment = TrainingComment(
      id: commentRef.id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(postRef, {'commentsCount': FieldValue.increment(1)});
    });
  }

  Stream<List<TrainingComment>> streamComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainingComment.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> applyTraining(TrainingApplication application) async {
    if (application.postId.trim().isEmpty || application.teacherId.trim().isEmpty) {
      throw ArgumentError('postId and teacherId must be provided');
    }

    final appRef = _applications.doc('${application.postId}_${application.teacherId}');
    final postRef = _posts.doc(application.postId);

    try {
      await _db.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw StateError('Training post no longer exists.');
        }

        final post = TrainingPost.fromMap(postSnapshot.id, postSnapshot.data()!);
        if (!post.isTraining || !post.isOpenVolunteer) {
          throw StateError('This training is not open for volunteer applications.');
        }
        if (post.isFull) {
          throw StateError('This training is already full.');
        }
        if (post.traineeIds.contains(application.teacherId)) {
          throw StateError('You are already enrolled in this training.');
        }

        final appSnapshot = await transaction.get(appRef);
        if (appSnapshot.exists) {
          final status = appSnapshot.data()?['status'] ?? 'pending';
          if (status == 'pending' || status == 'approved') {
            throw StateError('You already have an application for this training.');
          }
        }

        transaction.set(appRef, application.toMap());
      });
    } catch (e, s) {
      try {
        print('[TrainingService][applyTraining] error: $e');
        print(s);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> approveApplication(TrainingApplication application) async {
    final appRef = _applications.doc(application.id);
    final postRef = _posts.doc(application.postId);

    try {
      await _db.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw StateError('Training post no longer exists.');
        }

        final post = TrainingPost.fromMap(postSnapshot.id, postSnapshot.data()!);
        if (post.isFull && !post.traineeIds.contains(application.teacherId)) {
          throw StateError('No seats remain for this training.');
        }

        transaction.update(appRef, {'status': 'approved'});
        transaction.update(postRef, {
          'traineeIds': FieldValue.arrayUnion([application.teacherId]),
        });
      });
    } catch (e, s) {
      try {
        print('[TrainingService][approveApplication] error: $e');
        print(s);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> rejectApplication(String applicationId) async {
    await _applications.doc(applicationId).update({'status': 'rejected'});
  }

  Future<void> assignTraineeToTraining({
    required String postId,
    required String teacherId,
  }) async {
    if (postId.trim().isEmpty || teacherId.trim().isEmpty) {
      throw ArgumentError('postId and teacherId must be provided');
    }

    final postRef = _posts.doc(postId);
    try {
      await _db.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw StateError('Training post no longer exists.');
        }

        final post = TrainingPost.fromMap(postSnapshot.id, postSnapshot.data()!);
        if (post.isFull && !post.traineeIds.contains(teacherId)) {
          throw StateError('No seats remain for this training.');
        }

        transaction.update(postRef, {
          'traineeIds': FieldValue.arrayUnion([teacherId]),
        });
      });
    } catch (e, s) {
      try {
        print('[TrainingService][assignTraineeToTraining] error: $e');
        print(s);
      } catch (_) {}
      rethrow;
    }
  }

  Stream<List<TrainingApplication>> streamApplications({
    String? status,
    String? teacherId,
    String? postId,
  }) {
    // Fetch ordered applications, then filter client-side to avoid composite
    // Firestore index errors which would cause the admin UI to receive no data.
    final query = _applications.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      var apps = snapshot.docs
          .map((doc) => TrainingApplication.fromMap(doc.id, doc.data()))
          .toList();

      if (status != null) {
        apps = apps.where((a) => a.status == status).toList();
      }
      if (teacherId != null) {
        apps = apps.where((a) => a.teacherId == teacherId).toList();
      }
      if (postId != null) {
        apps = apps.where((a) => a.postId == postId).toList();
      }

      try {
        print('[TrainingService] streamApplications -> ${apps.length} apps (status=$status, teacherId=$teacherId, postId=$postId)');
      } catch (_) {}

      return apps;
    });
  }

  Stream<List<TrainingPost>> getPostsByAuthor(String authorId) {
    // Query ordered by createdAt then filter client-side by authorId to avoid
    // requiring a composite Firestore index (which resulted in empty UI).
    final query = _posts.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => TrainingPost.fromMap(doc.id, doc.data()))
          .where((p) => p.authorId == authorId)
          .toList();
      try {
        print('[TrainingService] getPostsByAuthor($authorId) -> ${posts.length}');
      } catch (_) {}
      return posts;
    }).handleError((e, s) {
      try {
        print('[TrainingService] getPostsByAuthor error: $e');
        print(s);
      } catch (_) {}
      throw e;
    });
  }

  Future<TeacherRecord?> getFacultyProfile(String authorId) async {
    final doc = await _teachers.doc(authorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TeacherRecord.fromMap(doc.id, doc.data()!);
  }
}