import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training.dart';

class TrainingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TrainingPost>> getTrainingPosts() {
    return _db.collection('training_posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => TrainingPost.fromMap(doc.id, doc.data())).toList()
    );
  }

  Future<void> applyForTraining(TrainingApplication app) async {
    await _db.collection('training_applications').doc(app.id).set(app.toMap());
  }
}