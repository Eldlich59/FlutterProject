import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/patient.dart';
import 'package:clinic_management/models/examination.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // Patient operations
  Future<List<Patient>> getPatients() async {
    final response = await supabase.from('BENHNHAN').select();

    return (response as List).map((json) => Patient.fromJson(json)).toList();
  }

  Future<void> addPatient(Patient patient) async {
    await supabase.from('BENHNHAN').insert(patient.toJson());
  }

  Future<void> updatePatient(Patient patient) async {
    await supabase
        .from('BENHNHAN')
        .update(patient.toJson())
        .eq('MaBN', patient.id);
  }

  Future<void> deletePatient(String id) async {
    await supabase.from('BENHNHAN').delete().eq('MaBN', id);
  }

  // Examination operations
  Future<List<Examination>> getExaminations({String? patientId}) async {
    var query = supabase.from('PHIEUKHAM').select();

    if (patientId != null) {
      query = query.eq('patient_id', patientId);
    }

    final data = await query;

    return data.map((json) => Examination.fromJson(json)).toList();
  }

  Future<void> addExamination(Examination examination) async {
    await supabase.from('PHIEUKHAM').insert(examination.toJson());
  }

  Future<void> updateExamination(Examination examination) async {
    await supabase
        .from('PHIEUKHAM')
        .update(examination.toJson())
        .eq('id', examination.id);
  }

  Future<void> deleteExamination(String id) async {
    await supabase.from('PHIEUKHAM').delete().eq('id', id);
  }
}
