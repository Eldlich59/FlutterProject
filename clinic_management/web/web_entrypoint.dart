import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:clinic_management/main.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for web
  if (kIsWeb) {
    // Configure databaseFactory for web platform
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Run the app
  runApp(const ClinicApp());
}
