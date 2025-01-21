import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/examination.dart';

class ExaminationService {
  final SupabaseClient _supabase;

  ExaminationService(this._supabase);

  Future<List<Examination>> getExaminations({String? patientId}) async {
    var query = _supabase.from('PHIEUKHAM').select(
        '*, BENHNHAN!inner(TenBN), BACSI!left(TenBS)'); // Add BACSI join

    if (patientId != null) {
      query = query.eq('MaBN', patientId);
    }

    final data = await query.order('NgayKham', ascending: false);

    return (data as List)
        .map((json) => Examination.fromJson({
              ...json,
              'TenBN': json['BENHNHAN']['TenBN'],
              'TenBS': json['BACSI']?['TenBS'], // Map the doctor name
            }))
        .toList();
  }

  Future<void> addExamination(Examination examination) async {
    await _supabase.from('PHIEUKHAM').insert(examination.toJson());
  }

  Future<void> updateExamination(Examination examination) async {
    await _supabase
        .from('PHIEUKHAM')
        .update(examination.toJson())
        .eq('MaPK', examination.id); // Changed from 'id' to 'MaPK'
  }

  Future<void> deleteExamination(String id) async {
    await _supabase
        .from('PHIEUKHAM')
        .delete()
        .eq('MaPK', id); // Changed from 'id' to 'MaPK'
  }
}
