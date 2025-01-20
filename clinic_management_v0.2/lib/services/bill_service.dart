import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/bill.dart';

class BillService {
  final SupabaseClient _supabase;

  BillService(this._supabase);

  Future<List<Bill>> getBills() async {
    final response = await _supabase.from('HOADONTHUOC').select('''
      *,
      bill_details:CHITIETHOADON(
        prescriptions:TOATHUOC(
          MaToa,
          BENHNHAN (
            MaBN,
            TenBN
          ),
          PHIEUKHAM (
            MaPK,
            TienKham
          )
        )
      )
    ''').order('Ngaylap', ascending: false);

    return (response as List).map((bill) => Bill.fromJson(bill)).toList();
  }

  Future<void> createBill({
    required List<String> prescriptionIds,
    required DateTime saleDate,
    required double totalCost,
  }) async {
    try {
      // Insert the main bill record
      final billResponse = await _supabase
          .from('HOADONTHUOC')
          .insert({
            'Ngaylap': saleDate.toIso8601String(),
            'TongTien': totalCost,
          })
          .select('MaHD')
          .single();

      final billId = billResponse['MaHD'];

      // Insert bill details
      for (var prescriptionId in prescriptionIds) {
        await _supabase.from('CHITIETHOADON').insert({
          'MaHD': billId,
          'MaToa': prescriptionId,
        });
      }
    } catch (e) {
      print('Create bill error: $e');
      throw Exception('Không thể tạo hóa đơn: $e');
    }
  }

  Future<void> updateBill({
    required String id,
    required List<String> prescriptionIds,
    required DateTime saleDate,
    required double totalCost,
  }) async {
    try {
      final billId = int.parse(id);

      // Update main bill record
      await _supabase.from('HOADONTHUOC').update({
        'Ngaylap': saleDate.toIso8601String(),
        'TongTien': totalCost,
      }).eq('MaHD', billId);

      // Delete existing details
      await _supabase.from('CHITIETHOADON').delete().eq('MaHD', billId);

      // Insert new details
      for (var prescriptionId in prescriptionIds) {
        await _supabase.from('CHITIETHOADON').insert({
          'MaHD': billId,
          'MaToa': prescriptionId,
        });
      }
    } catch (e) {
      print('Update bill error: $e');
      throw Exception('Không thể cập nhật hóa đơn: $e');
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Mã hóa đơn không hợp lệ');
      }

      // Delete child records first (CHITIETHOADON)
      await _supabase.from('CHITIETHOADON').delete().eq('MaHD', id);

      // Then delete the parent record (HOADONTHUOC)
      final result = await _supabase
          .from('HOADONTHUOC')
          .delete()
          .eq('MaHD', id)
          .select()
          .maybeSingle();

      if (result == null) {
        throw Exception('Không tìm thấy hóa đơn');
      }
    } catch (e) {
      print('Delete bill error: $e');
      if (e.toString().contains('invalid input syntax')) {
        throw Exception('Mã hóa đơn không hợp lệ');
      }
      if (e.toString().contains('foreign key constraint')) {
        throw Exception('Không thể xóa hóa đơn vì có dữ liệu liên quan');
      }
      throw Exception('Không thể xóa hóa đơn: ${e.toString()}');
    }
  }
}
