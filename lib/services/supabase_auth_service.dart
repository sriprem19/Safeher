import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class SupabaseAuthService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Send OTP to phone number
  static Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Format phone number with country code
      final formattedPhone = phoneNumber.startsWith('+') 
          ? phoneNumber 
          : '+91$phoneNumber';

      await _client.auth.signInWithOtp(
        phone: formattedPhone,
      );
      
      return true;
    } catch (e) {
      // Use debugPrint instead of print for better practices
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  static Future<AuthResponse?> verifyOTP(String phoneNumber, String otp) async {
    try {
      // Format phone number with country code
      final formattedPhone = phoneNumber.startsWith('+') 
          ? phoneNumber 
          : '+91$phoneNumber';

      final response = await _client.auth.verifyOTP(
        phone: formattedPhone,
        token: otp,
        type: OtpType.sms,
      );

      return response;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return null;
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Check if user is signed in
  static bool isSignedIn() {
    return _client.auth.currentUser != null;
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  // Validate Indian mobile number
  static bool isValidMobile(String mobile) {
    if (mobile.length != 10) return false;
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) return false;
    return true;
  }
}
