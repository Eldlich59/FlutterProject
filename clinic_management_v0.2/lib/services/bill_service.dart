import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/bill.dart';

class BillService {
  final SupabaseClient _supabase;

  BillService(this._supabase);

  Future<List<Bill>> getBills() async {
    final response = await _supabase.from('HOADONTHUOC').select('''
          *,
          TOATHUOC (
            *,
            BENHNHAN (
              TenBN
            )
          )
        ''').order('Ngaylap', ascending: false);

    return (response as List).map((bill) => Bill.fromJson(bill)).toList();
  }

  Future<void> createBill({
    required String prescriptionId,
    required DateTime saleDate,
    required double medicineCost,
  }) async {
    try {
      await _supabase.from('HOADONTHUOC').insert({
        'MaToa': prescriptionId,
        'Ngaylap': saleDate.toIso8601String(),
        'TienThuoc': medicineCost,
      });
    } catch (e) {
      throw Exception('Không thể tạo hóa đơn: $e');
    }
  }

  Future<void> updateBill({
    required String id,
    required String prescriptionId,
    required DateTime saleDate,
    required double medicineCost,
  }) async {
    await _supabase.from('HOADONTHUOC').update({
      'MaToa': prescriptionId,
      'Ngaylap': saleDate.toIso8601String(),
      'TienThuoc': medicineCost,
    }).eq('MaHD', id);
  }

  Future<void> deleteBill(String id) async {
    await _supabase.from('HOADONTHUOC').delete().eq('MaHD', id);
  }
}
