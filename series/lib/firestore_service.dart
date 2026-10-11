import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _series = FirebaseFirestore.instance.collection('series');
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // CREATE: เพิ่มซีรีส์พร้อมผูกกับเจ้าของ
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

  // READ: อ่านเฉพาะซีรีส์ของผู้ใช้ที่กำลังล็อกอินแบบเรียลไทม์
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMySeries() {
    return _series.where('userId', isEqualTo: _uid).snapshots();
  }

  // UPDATE: แก้ไขข้อมูลซีรีส์
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

  // DELETE: ลบซีรีส์
  static Future<void> delete(String docId) async {
    await _series.doc(docId).delete();
  }
}
