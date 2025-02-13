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
        BACSI(TenBS, TrangThai),
        CHUYENKHOA(MaCK, TenCK, TrangThaiHD),
        price_packages(id, name, price, is_active)
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
                'BACSI': json['BACSI'],
                'CHUYENKHOA': json['CHUYENKHOA'],
                'price_package_id': json['price_package_id'],
                'PRICE_PACKAGES': json['price_packages'],
              }))
          .toList();
    } catch (e) {
      print('Error fetching examinations: $e');
      throw Exception('Error fetching examinations: $e');
    }
  }

  Future<Map<String, dynamic>> getExaminationById(String examId) async {
    try {
      final response = await _supabase.from('PHIEUKHAM').select('''
        *,
        BENHNHAN (TenBN),
        BACSI (
          MaBS,
          TenBS,
          TrangThai
        ),
        CHUYENKHOA (
          MaCK,
          TenCK,
          TrangThaiHD
        )
      ''').eq('MaPK', examId).single();

      return response;
    } catch (e) {
      print('Error fetching examination by ID: $e');
      throw Exception('Error fetching examination: $e');
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
