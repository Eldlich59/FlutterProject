import '../models/medical_record.dart';
import '../database/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';

class MedicalRecordRepository {
  final DatabaseService? _databaseService;
  final Logger _logger = Logger();

  MedicalRecordRepository([this._databaseService]);

  Future<List<MedicalRecord>> getAllRecords() async {
    if (_databaseService == null) {
      // Return empty list for web platform
      return [];
    }
    try {
      final db = await _databaseService.database;
      final result = await db.query('PHIEUKHAM');
      return List.generate(
          result.length, (i) => MedicalRecord.fromJson(result[i]));
    } catch (e) {
      _logger.e('Error fetching all records: $e');
      throw DatabaseException('Failed to fetch medical records');
    }
  }

  Future<List<MedicalRecord>> getPatientMedicalRecords(String patientId) async {
    if (_databaseService == null) return [];
    if (patientId.isEmpty) {
      throw ArgumentError('Patient ID cannot be empty');
    }

    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'PHIEUKHAM',
        where: 'MaBN = ?',
        whereArgs: [patientId],
      );
      return List.generate(maps.length, (i) => MedicalRecord.fromJson(maps[i]));
    } catch (e) {
      _logger.e('Error fetching patient records: $e');
      throw DatabaseException('Failed to fetch patient medical records');
    }
  }

  Future<void> insertMedicalRecord(MedicalRecord record) async {
    if (_databaseService == null) return;
    try {
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        await txn.insert(
          'PHIEUKHAM',
          record.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      _logger.e('Error inserting record: $e');
      throw DatabaseException('Failed to insert medical record');
    }
  }

  Future<void> updateMedicalRecord(MedicalRecord record) async {
    if (_databaseService == null) return;
    if (record.id.isEmpty) {
      throw ArgumentError('Invalid medical record');
    }

    try {
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        await txn.update(
          'PHIEUKHAM',
          record.toJson(),
          where: 'MaPK = ?',
          whereArgs: [record.id],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      _logger.e('Error updating record: $e');
      throw DatabaseException('Failed to update medical record');
    }
  }

  Future<void> deleteMedicalRecord(String id) async {
    if (_databaseService == null) return;
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    try {
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        await txn.delete(
          'PHIEUKHAM',
          where: 'MaPK = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      _logger.e('Error deleting record: $e');
      throw DatabaseException('Failed to delete medical record');
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
}
