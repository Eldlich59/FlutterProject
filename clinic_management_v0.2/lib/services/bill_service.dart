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
            ),
            PHIEUKHAM (
              MaPK,
              TienKham
            )
          )
        ''').order('Ngaylap', ascending: false);

    return (response as List).map((bill) => Bill.fromJson(bill)).toList();
  }

  Future<void> createBill({
    required String prescriptionId,
    required DateTime saleDate,
    required double totalCost,
  }) async {
    try {
      await _supabase.from('HOADONTHUOC').insert({
        'MaToa': prescriptionId,
        'Ngaylap': saleDate.toIso8601String(),
        'TongTien': totalCost,
      });
    } catch (e) {
      throw Exception('Không thể tạo hóa đơn: $e');
    }
  }

  Future<void> updateBill({
    required String id,
    required String prescriptionId,
    required DateTime saleDate,
    required double totalCost,
  }) async {
    await _supabase.from('HOADONTHUOC').update({
      'MaToa': prescriptionId,
      'Ngaylap': saleDate.toIso8601String(),
      'TongTien': totalCost,
    }).eq('MaHD', int.parse(id));
  }

  Future<void> deleteBill(String id) async {
    try {
      await _supabase.from('HOADONTHUOC').delete().eq('MaHD', id);
    } catch (e) {
      throw Exception('Không thể xóa hóa đơn: $e');
    }
  }
}
