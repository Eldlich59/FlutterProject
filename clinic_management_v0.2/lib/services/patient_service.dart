import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/patient.dart';

class PatientService {
  final SupabaseClient _supabase;

  PatientService(this._supabase);

  Future<List<Patient>> getPatients() async {
    final response = await _supabase
        .from('BENHNHAN')
        .select('MaBN, TenBN, NgaySinh, GioiTinh, DiaChi, SDT')
        .order('MaBN');

    if (response.isEmpty) {
      return [];
    }

    return (response as List<dynamic>)
        .map((json) => Patient.fromJson(json))
        .toList();
  }

  Future<void> addPatient(Patient patient) async {
    await _supabase.from('BENHNHAN').insert(patient.toJson());
  }

  Future<void> updatePatient(Patient patient) async {
    await _supabase
        .from('BENHNHAN')
        .update(patient.toJson())
        .eq('MaBN', patient.id!);
  }

  Future<void> deletePatient(String id) async {
    await _supabase.from('BENHNHAN').delete().eq('MaBN', id);
  }
}
