import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/specialty.dart';
import 'package:uuid/uuid.dart';

class SpecialtyService {
  final SupabaseClient _supabase;

  SpecialtyService(this._supabase);

  Future<List<Specialty>> getSpecialties() async {
    final response = await _supabase
        .from('CHUYENKHOA')
        .select()
        .order('TenCK'); // Added ordering and explicit response handling

    return (response as List<dynamic>)
        .map((json) => Specialty.fromJson(json))
        .toList();
  }

  Future<List<Specialty>> getDoctorSpecialties(String doctorId) async {
    final response = await _supabase
        .from('BACSI_CHUYENKHOA')
        .select('CHUYENKHOA(*)')
        .eq('MaBS', doctorId);

    return (response as List)
        .map((json) => Specialty.fromJson(json['CHUYENKHOA']))
        .toList();
  }

  Future<void> addSpecialty({
    required String name,
    required bool isActive,
    required bool isSelfRegistration,
  }) async {
    final uuid = const Uuid().v4();
    await _supabase.from('CHUYENKHOA').insert({
      'MaCK': uuid,
      'TenCK': name,
      'TrangThaiHD': isActive,
      'HinhThucCP': isSelfRegistration,
    });
  }

  Future<void> updateSpecialty({
    required String id,
    required String name,
    required bool isActive,
    required bool isSelfRegistration,
  }) async {
    await _supabase.from('CHUYENKHOA').update({
      'TenCK': name,
      'TrangThaiHD': isActive,
      'HinhThucCP': isSelfRegistration,
    }).eq('MaCK', id);
  }

  Future<void> deleteSpecialty(String id) async {
    await _supabase.from('CHUYENKHOA').delete().eq('MaCK', id);
  }

  Future<void> assignSpecialtyToDoctor(
      String doctorId, String specialtyId) async {
    await _supabase.from('BACSI_CHUYENKHOA').insert({
      'MaBS': doctorId,
      'MaCK': specialtyId,
    });
  }

  Future<void> removeSpecialtyFromDoctor(
      String doctorId, String specialtyId) async {
    await _supabase
        .from('BACSI_CHUYENKHOA')
        .delete()
        .match({'MaBS': doctorId, 'MaCK': specialtyId});
  }
}
