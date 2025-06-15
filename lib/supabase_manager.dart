import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();
  factory SupabaseManager() => _instance;
  SupabaseManager._internal();

  static const String supabaseUrl = 'https://hawhmiecntmfigpaaaok.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhhd2htaWVjbnRtZmlncGFhYW9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0NDMyMzMsImV4cCI6MjA2NTAxOTIzM30.4x4KUW0hMpAlsa1rZ5YFebdhI-sD7Z4BxEYo3PpU_Ig';

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}