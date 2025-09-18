import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final _db = FirebaseFirestore.instance;

  /// Returns a stream of the user's document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String userDocId) {
    // Ensure auth is established BEFORE emitting any snapshots to avoid
    // 'Not authenticated' exceptions in listeners.
    return Stream.fromFuture(_ensureAuth()).asyncExpand((_) {
      final safeId = _ownerId();
      return _db.collection('users').doc(safeId).snapshots();
    });
  }

  /// Ensures user doc exists and merges profile basics.
  Future<void> upsertUserProfile({
    required String userDocId,
    required String userName,
    required String phoneNumber,
  }) async {
    try {
      await _ensureAuth();
      final safeId = _ownerId();
      final ref = _db.collection('users').doc(safeId);
      final snap = await ref.get();

      await ref.set({
        'userName': userName.trim(),
        'phoneNumber': phoneNumber.trim(),
        if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Surface detailed errors to caller
      throw Exception('upsertUserProfile failed: $e');
    }
  }

  /// Saves emergency contacts (overwrites the array).
  Future<void> saveEmergencyContacts({
    required String userDocId,
    required List<Map<String, String>> contacts,
  }) async {
    try {
      await _ensureAuth();
      final safeId = _ownerId();
      // Normalize contact entries to avoid malformed writes
      final normalized = contacts
          .map((c) => {
                'name': (c['name'] ?? '').trim(),
                'phone': (c['phone'] ?? '').trim(),
              })
          .toList();

      await _db.collection('users').doc(safeId).set({
        'emergencyContacts': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('saveEmergencyContacts failed: $e');
    }
  }

  /// Helper to read the array once (not streaming).
  Future<List<Map<String, String>>> getEmergencyContactsOnce(String userDocId) async {
    try {
      await _ensureAuth();
      final safeId = _ownerId();
      final snap = await _db.collection('users').doc(safeId).get();
      final data = snap.data();
      final list = (data?['emergencyContacts'] as List<dynamic>?) ?? [];
      return list
          .map<Map<String, String>>((e) => {
                'name': (e is Map && e['name'] != null) ? e['name'].toString() : '',
                'phone': (e is Map && e['phone'] != null) ? e['phone'].toString() : '',
              })
          .toList();
    } catch (e) {
      throw Exception('getEmergencyContactsOnce failed: $e');
    }
  }

  /// Adds a panic log with contact results
  Future<void> addPanicLog({
    required String userDocId,
    required String message,
    String? locationLink,
    required List<Map<String, dynamic>> contactResults,
  }) async {
    try {
      await _ensureAuth();
      final safeId = _ownerId();
      await _db.collection('users').doc(safeId).collection('panicLogs').add({
        'message': message,
        'locationLink': locationLink,
        'contactResults': contactResults,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('addPanicLog failed: $e');
    }
  }

  /// Gets panic logs for a user, ordered by timestamp descending
  Stream<QuerySnapshot<Map<String, dynamic>>> getPanicLogsStream(String userDocId) {
    final safeId = _ownerId();
    return _db
        .collection('users')
        .doc(safeId)
        .collection('panicLogs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  String _sanitizeDocId(String id) {
    // Firestore doc IDs cannot contain '/'; trim whitespace
    return id.trim().replaceAll('/', '_');
  }

  Future<void> _ensureAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        // If rules require auth, this ensures request.auth != null
        rethrow;
      }
    }
  }

  String _ownerId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Not authenticated');
    }
    return uid;
  }
}
