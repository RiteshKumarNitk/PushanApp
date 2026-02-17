import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Hardcoded values as requested to avoid .env dependence
  static const String _url = "https://gileyahzdpoyjgrztxow.supabase.co";
  static const String _anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdpbGV5YWh6ZHBveWpncnp0eG93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2NzE2MTQsImV4cCI6MjA3NzI0NzYxNH0.b9RNGS-r4B91y96nxdUjK_jNtaG_5Dm-KwBSKtlPMYs";

  static Future<void> initialize() async {
    // dotenv.load(fileName: ".env"); // Removed
    
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
