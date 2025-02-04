import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/inventory/medicine.dart' as med;

class MedicineService {
  final SupabaseClient _supabase;

  MedicineService(this._supabase);

  Future<List<med.Medicine>> getMedicines() async {
    try {
      final response = await _supabase
          .from('THUOC') // Changed from 'medicines' to 'THUOC'
          .select()
          .order('TenThuoc', ascending: true);

      print('Fetched medicines response: $response'); // Debug log

      return (response as List<dynamic>)
          .map((json) => med.Medicine.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching medicines: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> addMedicine(med.Medicine medicine) async {
    final medicineJson = medicine.toJson();
    // Xóa MaThuoc khỏi JSON khi thêm mới để Supabase tự tạo ID
    medicineJson.remove('MaThuoc');
    await _supabase.from('THUOC').insert(medicineJson);
  }

  Future<void> deleteMedicine(String id) async {
    // Change parameter type to String
    await _supabase.from('THUOC').delete().eq('MaThuoc', id);
  }

  Future<void> updateMedicine(med.Medicine medicine) async {
    await _supabase
        .from('THUOC')
        .update(medicine.toJson())
        .eq('MaThuoc', medicine.id);
  }
}
