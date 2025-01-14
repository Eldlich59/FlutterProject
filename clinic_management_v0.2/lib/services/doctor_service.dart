import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Add this import
import 'package:clinic_management/models/doctor.dart';

class DoctorService {
  final SupabaseClient _supabase;

  DoctorService(this._supabase);

  Future<List<Doctor>> getDoctor() async {
    final response = await _supabase.from('BACSI').select();

    if (response.isEmpty) {
      return [];
    }

    return (response as List).map((json) => Doctor.fromJson(json)).toList();
  }

  Future<Doctor> getDoctorById(String id) async {
    final response =
        await _supabase.from('BACSI').select().eq('MaBS', id).single();

    return Doctor.fromJson(response);
  }

  Future<void> addDoctor(Doctor doctor) async {
    final uuid = const Uuid().v4(); // Generate new UUID
    final doctorData = doctor.toJson();
    doctorData['MaBS'] = uuid; // Set the UUID

    await _supabase.from('BACSI').insert(doctorData);
  }

  Future<void> updateDoctor(Doctor doctor) async {
    await _supabase.from('BACSI').update(doctor.toJson()).eq('MaBS', doctor.id);
  }

  Future<void> deleteDoctor(String id) async {
    await _supabase.from('BACSI').delete().eq('MaBS', id);
  }
}
