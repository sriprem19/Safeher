import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://aubhsxfehaxhjfvlsbyc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1YmhzeGZlaGF4aGpmdmxzYnljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwODMzODksImV4cCI6MjA3MzY1OTM4OX0.rCn3fB1FsWBq9LB0DOgS21AGcLAhMfyYvXp64PXWEM0';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
