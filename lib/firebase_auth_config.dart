import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthConfig {
  static Future<void> configureForDevelopment() async {
    // Use Firebase Auth emulator for development
    // This bypasses billing requirements
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
  
  static Future<void> configureForProduction() async {
    // Production configuration - requires billing enabled
    // No additional configuration needed
  }
}
