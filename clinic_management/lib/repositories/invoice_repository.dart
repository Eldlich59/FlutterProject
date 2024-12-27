import '../database/database_service.dart';
import '../models/invoice.dart';
import 'package:sqflite/sqflite.dart';

const conflictAlgorithm = ConflictAlgorithm.replace;

class InvoiceRepository {
  final DatabaseService _databaseService;

  InvoiceRepository(this._databaseService);

  Future<List<Invoice>> getAllInvoices() async {
    final db = await _databaseService.database;
    final result = await db.query('HOADONTHUOC');
    return result.map((map) => Invoice.fromJson(map)).toList();
  }

  Future<void> insertInvoice(Invoice invoice) async {
    final db = await _databaseService.database;
    await db.insert(
      'HOADONTHUOC',
      invoice.toJson(),
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  Future<double> getDailyRevenue(DateTime date) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT SUM(TienThuoc) as total
      FROM HOADONTHUOC
      WHERE date(Ngayban) = date(?)
    ''', [date.toIso8601String().split('T').first]);
    return (result.first['total'] as num? ?? 0).toDouble();
  }

  Future<Invoice?> getInvoice(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'HOADONTHUOC',
      where: 'MaHD = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Invoice.fromJson(maps.first) : null;
  }

  Future<void> updateInvoice(Invoice invoice) async {
    final db = await _databaseService.database;
    await db.update(
      'HOADONTHUOC',
      invoice.toJson(),
      where: 'MaHD = ?',
      whereArgs: [invoice.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
