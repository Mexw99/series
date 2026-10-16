import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _series = FirebaseFirestore.instance.collection('series');
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<void> add(
    String title,
    String content,
    String date,
    double rating,
    String image,
  ) async {
    await _series.add({
      'title': title,
      'content': content,
      'date': date,
      'rating': rating,
      'image': image,
      'userId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMySeries() {
    return _series.where('userId', isEqualTo: _uid).snapshots();
  }

  static Future<void> update(
    String docId,
    String title,
    String content,
    String date,
    double rating,
    String image,
  ) async {
    await _series.doc(docId).update({
      'title': title,
      'content': content,
      'date': date,
      'rating': rating,
      'image': image,
    });
  }

  static Future<void> delete(String docId) async {
    await _series.doc(docId).delete();
  }
}
