import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// Supabase client instance
final supabase = Supabase.instance.client;

// Flag to track initialization status
bool supabaseInitialized = false;

// Initialize Supabase
Future<void> initializeSupabase() async {
  try {
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
    
    supabaseInitialized = true;
    debugPrint('Supabase initialized successfully');
    
    // Verify tables exist or catch errors
    await _verifyDatabaseTables();
    
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
    supabaseInitialized = false;
    rethrow;
  }
}

// Verify database tables exist
Future<void> _verifyDatabaseTables() async {
  try {
    final tables = [
      'patients',
      'profiles',
      'health_metrics',
      'medical_records',
      'articles'
    ];
    
    for (final table in tables) {
      try {
        // Try a simple query on each table to verify it exists
        await supabase.from(table).select('id').limit(1);
        debugPrint('Table $table exists');
      } catch (e) {
        // Log if a table doesn't exist
        debugPrint('Table $table does not exist: $e');
      }
    }
  } catch (e) {
    debugPrint('Error verifying database tables: $e');
  }
}

// Helper method to check if a table exists
Future<bool> tableExists(String tableName) async {
  try {
    await supabase.from(tableName).select('id').limit(1);
    return true;
  } catch (e) {
    // If error contains "relation does not exist", table doesn't exist
    if (e.toString().contains("relation") && 
        e.toString().contains("does not exist")) {
      return false;
    }
    // For other errors, we assume the table might exist but there's another issue
    return true;
  }
}
