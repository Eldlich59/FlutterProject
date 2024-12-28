import '../database/database_service.dart';
import '../models/patient.dart';
import 'package:sqflite/sqflite.dart';

class PatientRepository {
  final DatabaseService? _databaseService;

  PatientRepository([this._databaseService]);

  Future<List<Patient>> getAllPatients() async {
    if (_databaseService == null) {
      // Return empty list or mock data for web
      return [];
    }
    try {
      final db = await _databaseService.database;
      final result = await db.query('BENHNHAN');
      return result.map((map) => Patient.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get patients: $e');
    }
  }

  Future<Patient?> getPatient(String maBN) async {
    if (_databaseService == null) {
      // Return null or mock data for web
      return null;
    }
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'BENHNHAN',
        where: 'MaBN = ?',
        whereArgs: [maBN],
      );

      if (maps.isEmpty) return null;
      return Patient.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to get patient: $e');
    }
  }

  Future<void> createPatient(Patient patient) async {
    if (_databaseService == null) {
      // Handle null database service for web
      return;
    }
    try {
      final db = await _databaseService.database;
      await db.insert(
        'BENHNHAN',
        patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to create patient: $e');
    }
  }

  Future<void> updatePatient(Patient patient) async {
    if (_databaseService == null) {
      // Handle null database service for web
      return;
    }
    try {
      final db = await _databaseService.database;
      await db.update(
        'BENHNHAN',
        patient.toMap(),
        where: 'MaBN = ?',
        whereArgs: [patient.maBN],
      );
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  Future<void> deletePatient(String maBN) async {
    if (_databaseService == null) {
      // Handle null database service for web
      return;
    }
    try {
      final db = await _databaseService.database;
      await db.delete(
        'BENHNHAN',
        where: 'MaBN = ?',
        whereArgs: [maBN],
      );
    } catch (e) {
      throw Exception('Failed to delete patient: $e');
    }
  }

  Future<void> addPatient(Patient patient) async {
    return createPatient(patient); // Calls existing createPatient method
  }
}
