import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/doctor.dart';

class DoctorService {
  final SupabaseClient _supabase;

  DoctorService(this._supabase);

  Future<List<Doctor>> getDoctors() async {
    final response = await _supabase.from('BACSI').select();

    if (response.isEmpty) {
      return [];
    }

    return (response as List).map((json) => Doctor.fromJson(json)).toList();
  }

  Future<void> addDoctor(Doctor doctor) async {
    await _supabase.from('BACSI').insert(doctor.toJson());
  }

  Future<void> updateDoctor(Doctor doctor) async {
    await _supabase.from('BACSI').update(doctor.toJson()).eq('MaBS', doctor.id);
  }

  Future<void> deleteDoctor(String id) async {
    await _supabase.from('BACSI').delete().eq('MaBS', id);
  }
}
