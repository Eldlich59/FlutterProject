import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/examination.dart';

class ExaminationService {
  final SupabaseClient _supabase;

  ExaminationService(this._supabase);

  Future<List<Examination>> getExaminations({String? patientId}) async {
    try {
      var query = _supabase.from('PHIEUKHAM').select('''
        *, 
        BENHNHAN!inner(TenBN), 
        BACSI(TenBS),
        CHUYENKHOA(MaCK, TenCK)
      ''');

      if (patientId != null) {
        query = query.eq('MaBN', patientId);
      }

      final response = await query.order('NgayKham', ascending: false);

      return (response as List)
          .map((json) => Examination.fromJson({
                ...json,
                'TenBN': json['BENHNHAN']?['TenBN'],
                'TenBS': json['BACSI']?['TenBS'],
                'MaCK': json['CHUYENKHOA']?['MaCK'],
                'TenCK': json['CHUYENKHOA']?['TenCK'],
              }))
          .toList();
    } catch (e) {
      print('Error fetching examinations: $e');
      return [];
    }
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
