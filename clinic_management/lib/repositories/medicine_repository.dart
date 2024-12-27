import '../models/medicine.dart';
import '../database/database_service.dart';
import 'package:sqflite/sqflite.dart';

class MedicineRepository {
  final DatabaseService _databaseService;

  MedicineRepository([DatabaseService? databaseService])
      : _databaseService = databaseService ?? DatabaseService.instance;

  Future<List<Medicine>> getAllMedicines() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('THUOC');
    return List.generate(maps.length, (i) => Medicine.fromJson(maps[i]));
  }

  Future<Medicine> getMedicine(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'THUOC',
      where: 'MaThuoc = ?',
      whereArgs: [id],
    );
    return Medicine.fromJson(maps.first);
  }

  Future<void> insertMedicine(Medicine medicine) async {
    final db = await _databaseService.database;
    await db.insert(
      'THUOC',
      medicine.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final db = await _databaseService.database;
    await db.update(
      'THUOC',
      medicine.toJson(),
      where: 'MaThuoc = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<void> deleteMedicine(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'THUOC',
      where: 'MaThuoc = ?',
      whereArgs: [id],
    );
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'THUOC',
      where: 'TenThuoc LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) => Medicine.fromJson(maps[i]));
  }
}
