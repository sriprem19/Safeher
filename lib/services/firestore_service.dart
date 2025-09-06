import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final _db = FirebaseFirestore.instance;

  /// Returns a stream of the user's document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String userDocId) {
    return _db.collection('users').doc(userDocId).snapshots();
  }

  /// Ensures user doc exists and merges profile basics.
  Future<void> upsertUserProfile({
    required String userDocId,
    required String userName,
    required String phoneNumber,
  }) async {
    final ref = _db.collection('users').doc(userDocId);
    final snap = await ref.get();

    await ref.set({
      'userName': userName,
      'phoneNumber': phoneNumber,
      if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Saves emergency contacts (overwrites the array).
  Future<void> saveEmergencyContacts({
    required String userDocId,
    required List<Map<String, String>> contacts,
  }) async {
    await _db.collection('users').doc(userDocId).set({
      'emergencyContacts': contacts,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Helper to read the array once (not streaming).
  Future<List<Map<String, String>>> getEmergencyContactsOnce(String userDocId) async {
    final snap = await _db.collection('users').doc(userDocId).get();
    final data = snap.data();
    final list = (data?['emergencyContacts'] as List<dynamic>?) ?? [];
    return list.map<Map<String, String>>((e) => {
      'name': (e['name'] ?? '').toString(),
      'phone': (e['phone'] ?? '').toString(),
    }).toList();
  }

  /// Adds a panic log with contact results
  Future<void> addPanicLog({
    required String userDocId,
    required String message,
    String? locationLink,
    required List<Map<String, dynamic>> contactResults,
  }) async {
    await _db.collection('users').doc(userDocId).collection('panicLogs').add({
      'message': message,
      'locationLink': locationLink,
      'contactResults': contactResults,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Gets panic logs for a user, ordered by timestamp descending
  Stream<QuerySnapshot<Map<String, dynamic>>> getPanicLogsStream(String userDocId) {
    return _db
        .collection('users')
        .doc(userDocId)
        .collection('panicLogs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
