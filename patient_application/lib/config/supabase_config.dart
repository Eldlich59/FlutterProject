import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client instance
final supabase = Supabase.instance.client;

// Initialize Supabase
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'https://cywiojhihrdkzporqblt.supabase.co',
      defaultValue: 'https://cywiojhihrdkzporqblt.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5d2lvamhpaHJka3pwb3JxYmx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MTcxMDAsImV4cCI6MjA2MDE5MzEwMH0.konPbBj9358ZJKKzVktlBmTCOAJWEvEU9fhFPHJjkSo',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5d2lvamhpaHJka3pwb3JxYmx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MTcxMDAsImV4cCI6MjA2MDE5MzEwMH0.konPbBj9358ZJKKzVktlBmTCOAJWEvEU9fhFPHJjkSo',
    ),
  );
}
