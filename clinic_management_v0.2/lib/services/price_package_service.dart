import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/price_package.dart';

class PricePackageService {
  final SupabaseClient _supabase;

  PricePackageService(this._supabase);

  Future<List<PricePackage>> getAllPackages() async {
    final response =
        await _supabase.from('price_packages').select().order('created_at');

    return (response as List)
        .map((json) => PricePackage.fromJson(json))
        .toList();
  }

  Future<List<PricePackage>> getPackagesByChuyenKhoa(
      String chuyenKhoaId) async {
    final response = await _supabase
        .from('price_packages')
        .select()
        .eq('chuyen_khoa_id', chuyenKhoaId)
        .order('created_at');

    return (response as List)
        .map((json) => PricePackage.fromJson(json))
        .toList();
  }

  Future<PricePackage> createPackage(PricePackage package) async {
    final response = await _supabase
        .from('price_packages')
        .insert(package.toJson()..remove('id')) // Remove id from the insert
        .select()
        .single();

    return PricePackage.fromJson(response);
  }

  Future<PricePackage> updatePackage(PricePackage package) async {
    final response = await _supabase
        .from('price_packages')
        .update(package.toJson())
        .eq('id', package.id)
        .select()
        .single();

    return PricePackage.fromJson(response);
  }

  Future<void> deletePackage(String id) async {
    await _supabase.from('price_packages').delete().eq('id', id);
  }

  Future<void> togglePackageStatus(String id, bool isActive) async {
    await _supabase
        .from('price_packages')
        .update({'is_active': isActive}).eq('id', id);
  }
}
