import '../models/prescription.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';

class PrescriptionRepository {
  final DatabaseService _databaseService;

  PrescriptionRepository(this._databaseService);

  Future<List<Prescription>> getAllPrescriptions() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> prescriptionMaps =
        await db.query('TOATHUOC');

    List<Prescription> prescriptions = [];
    for (var map in prescriptionMaps) {
      // Get prescription details
      final List<Map<String, dynamic>> detailMaps = await db.query(
        'CHITIETTOATHUOC',
        where: 'MaToa = ?',
        whereArgs: [map['MaToa']],
      );

      // Convert details to PrescriptionDetail objects
      final details = detailMaps
          .map((detail) => PrescriptionDetail.fromJson(detail))
          .toList();
      // Create Prescription object with details
      prescriptions.add(Prescription.fromJson({...map, 'details': details}));
      // Create Prescription object with details
      prescriptions.add(Prescription.fromJson({...map, 'details': detailMaps}));
    }

    return prescriptions;
  }

  Future<void> insertPrescription(Prescription prescription) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      // Insert prescription
      await txn.insert(
        'TOATHUOC',
        {
          'MaToa': prescription.id,
          'Bsketoa': prescription.doctorName,
          'Ngayketoa': prescription.prescriptionDate.toIso8601String(),
          'MaBN': prescription.patientId,
          'MaPK': prescription.medicalRecordId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert prescription details
      for (var detail in prescription.details) {
        await txn.insert(
          'CHITIETTOATHUOC',
          {
            'MaToa': prescription.id,
            'MaThuoc': detail.medicineId,
            'Sluong': detail.quantity,
            'Cdung': detail.usage,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<Prescription> updatePrescription(Prescription prescription) async {
    final db = await _databaseService.database;
    await db.update(
      'TOATHUOC',
      prescription.toMap(),
      where: 'MaToa = ?',
      whereArgs: [prescription.id],
    );
    return prescription;
  }

  Future<Prescription?> getPrescriptionById(String id) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'TOATHUOC',
      where: 'MaToa = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Prescription.fromMap(maps.first);
  }

  Future<void> deletePrescription(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'TOATHUOC',
      where: 'MaToa = ?',
      whereArgs: [id],
    );
  }
}
