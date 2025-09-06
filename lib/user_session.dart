// lib/user_session.dart
import 'package:firebase_auth/firebase_auth.dart';

class UserSession {
  static String? userName;
  static String? phoneNumber;

  /// Prefer Firebase Auth UID if signed in; else derive a stable id from userName.
  static String get userId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;

    // Fallback: derived id from name (lowercase, underscores). Avoid spaces/specials.
    final name = (userName ?? '').trim().toLowerCase();
    if (name.isNotEmpty) {
      final derived = name.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]+'), '');
      if (derived.isNotEmpty) return 'name_$derived';
    }

    // Last resort: phone (shouldn’t happen if your flow sets name)
    final phone = (phoneNumber ?? '').trim();
    if (phone.isNotEmpty) return 'phone_$phone';

    return ''; // not ready
  }

  static bool get isReady => userId.isNotEmpty;
}
