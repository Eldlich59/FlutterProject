import '../models/medicine.dart';
import '../database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class MedicineRepository {
  final DatabaseService? _databaseService;

  MedicineRepository([this._databaseService]);

  Future<List<Medicine>> getAllMedicines() async {
    if (_databaseService == null) {
      // Return empty list for web platform
      return [];
    }
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('THUOC');
    return List.generate(maps.length, (i) => Medicine.fromJson(maps[i]));
  }

  Future<Medicine> getMedicine(String id) async {
    if (_databaseService == null) {
      throw Exception('Database service not available');
    }
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'THUOC',
      where: 'MaThuoc = ?',
      whereArgs: [id],
    );
    return Medicine.fromJson(maps.first);
  }

  Future<void> insertMedicine(Medicine medicine) async {
    if (_databaseService == null) return;
    final db = await _databaseService.database;
    await db.insert(
      'THUOC',
      medicine.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMedicine(Medicine medicine) async {
    if (_databaseService == null) return;
    final db = await _databaseService.database;
    await db.update(
      'THUOC',
      medicine.toJson(),
      where: 'MaThuoc = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<void> deleteMedicine(String id) async {
    if (_databaseService == null) return;
    final db = await _databaseService.database;
    await db.delete(
      'THUOC',
      where: 'MaThuoc = ?',
      whereArgs: [id],
    );
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    if (_databaseService == null) {
      return [];
    }
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'THUOC',
      where: 'TenThuoc LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) => Medicine.fromJson(maps[i]));
  }
}
