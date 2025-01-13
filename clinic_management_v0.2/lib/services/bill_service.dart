import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/bill.dart';

class BillService {
  final SupabaseClient _supabase;

  BillService(this._supabase);

  Future<List<Bill>> getBills() async {
    final response = await _supabase
        .from('HOADONTHUOC')
        .select()
        .order('Ngayban', ascending: false);

    if (response.isEmpty) {
      return [];
    }

    return (response as List).map((json) => Bill.fromJson(json)).toList();
  }

  Future<void> createBill({
    required String prescriptionId,
    required DateTime saleDate,
    required double medicineCost,
  }) async {
    await _supabase.from('HOADONTHUOC').insert({
      'MaToa': prescriptionId,
      'Ngayban': saleDate.toIso8601String(),
      'TienThuoc': medicineCost,
    });
  }

  Future<void> updateBill({
    required String id,
    required String prescriptionId,
    required DateTime saleDate,
    required double medicineCost,
  }) async {
    await _supabase.from('HOADONTHUOC').update({
      'MaToa': prescriptionId,
      'Ngayban': saleDate.toIso8601String(),
      'TienThuoc': medicineCost,
    }).eq('MaHD', id);
  }

  Future<void> deleteBill(String id) async {
    await _supabase.from('HOADONTHUOC').delete().eq('MaHD', id);
  }
}
