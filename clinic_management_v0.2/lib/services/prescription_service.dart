import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/prescription.dart';

class PrescriptionService {
  final SupabaseClient _supabase;

  PrescriptionService(this._supabase);

  Future<List<Prescription>> getPrescriptions() async {
    try {
      final response = await _supabase.from('TOATHUOC').select('''
            *,
            BACSI:MaBS (
              TenBS
            ),
            BENHNHAN:MaBN (
              TenBN
            )
          ''').order('Ngayketoa', ascending: false);

      return (response as List).map((prescription) {
        final doctorData = prescription['BACSI'] as Map<String, dynamic>?;
        final patientData = prescription['BENHNHAN'] as Map<String, dynamic>?;
        return Prescription.fromJson({
          ...prescription,
          'doctor_name': doctorData?['TenBS'],
          'patient_name': patientData?['TenBN'],
        });
      }).toList();
    } catch (e, stackTrace) {
      print('Error fetching prescriptions: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<List<PrescriptionDetail>> getPrescriptionDetails(
      String prescriptionId) async {
    try {
      print(
          'Fetching details for prescription: $prescriptionId'); // Debug print

      final response = await _supabase.from('CHITIETTOATHUOC').select('''
            *,
            thuoc:THUOC (
              MaThuoc,
              TenThuoc,
              DonVi,
              DonGia,
              SoLuongTon
            )
          ''').eq('MaToa', prescriptionId);

      print('Raw details response: $response'); // Debug print

      if (response.isEmpty) {
        print('Response is empty'); // Debug print
        return [];
      }

      return (response as List).map((json) {
        try {
          return PrescriptionDetail.fromJson(json);
        } catch (e) {
          print('Error parsing prescription detail: $e'); // Debug print
          print('Problematic JSON: $json'); // Debug print
          rethrow;
        }
      }).toList();
    } catch (e, stackTrace) {
      print('Error fetching prescription details: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<void> createPrescription(
    String doctorId,
    List<PrescriptionDetail> details, {
    required String patientId,
    required String examId,
    required DateTime prescriptionDate,
  }) async {
    try {
      print('Creating prescription...'); // Debug print
      final prescription = {
        'MaBS': doctorId,
        'Ngayketoa': prescriptionDate.toIso8601String(), // Format date properly
        'MaBN': patientId,
        'MaPK': examId,
      };

      print('Prescription data: $prescription'); // Debug print

      final prescriptionResponse = await _supabase
          .from('TOATHUOC')
          .insert(prescription)
          .select()
          .single();

      print('Created prescription: $prescriptionResponse'); // Debug print

      final prescriptionId = prescriptionResponse['MaToa'];

      for (final detail in details) {
        final detailData = {
          'MaToa': prescriptionId,
          'MaThuoc': int.tryParse(detail.medicineId) ??
              detail.medicineId, // Handle type conversion
          'Sluong': detail.quantity,
          'Cdung': detail.usage,
        };

        print('Inserting detail: $detailData'); // Debug print
        await _supabase.from('CHITIETTOATHUOC').insert(detailData);
      }
    } catch (e, stackTrace) {
      print('Error creating prescription: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  Future<void> updatePrescription(
    String prescriptionId,
    String doctorId,
    List<PrescriptionDetail> details, {
    DateTime? prescriptionDate,
  }) async {
    try {
      final prescription = {
        'MaBS': doctorId,
        if (prescriptionDate != null)
          'Ngayketoa': prescriptionDate.toIso8601String(), // Add date update
      };

      await _supabase
          .from('TOATHUOC')
          .update(prescription)
          .eq('MaToa', prescriptionId);

      // Delete existing details
      await _supabase
          .from('CHITIETTOATHUOC')
          .delete()
          .eq('MaToa', prescriptionId);

      // Insert new details
      for (final detail in details) {
        final detailData = {
          'MaToa': prescriptionId,
          'MaThuoc': detail.medicineId,
          'Sluong': detail.quantity,
          'Cdung': detail.usage,
        };

        await _supabase.from('CHITIETTOATHUOC').insert(detailData);
      }
    } catch (e) {
      print('Error updating prescription: $e');
      rethrow;
    }
  }

  Future<void> deletePrescription(String prescriptionId) async {
    try {
      // First delete all prescription details
      await _supabase
          .from('CHITIETTOATHUOC')
          .delete()
          .eq('MaToa', prescriptionId);

      // Then delete the prescription
      await _supabase.from('TOATHUOC').delete().eq('MaToa', prescriptionId);
    } catch (e) {
      print('Error deleting prescription: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPrescriptionMedicines(
      String prescriptionId) async {
    final response = await _supabase.from('CHITIETTOATHUOC').select('''
      *,
      THUOC (
        TenThuoc,
        DonVi,
        DonGia
      )
    ''').eq('MaToa', prescriptionId);

    if (response.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAvailablePrescriptions() async {
    final response = await _supabase
        .from('TOATHUOC')
        .select('''
          *,
          BENHNHAN (TenBN),
          HOADONTHUOC!left (MaHD)
        ''')
        .filter('HOADONTHUOC.MaHD', 'is',
            null) // Only get prescriptions without bills
        .order('Ngayketoa', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> getPatientNameById(String patientId) async {
    try {
      final response = await _supabase
          .from('BENHNHAN')
          .select('TenBN')
          .eq('MaBN', patientId)
          .single();
      return response['TenBN'] as String?;
    } catch (e) {
      print('Error fetching patient name: $e');
      return null;
    }
  }

  Future<List<Prescription>> searchPrescriptions({
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('TOATHUOC').select('''
        *,
        BACSI:MaBS (
          TenBS
        ),
        BENHNHAN:MaBN (
          TenBN
        )
      ''');

      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.or(
            'BENHNHAN.TenBN.ilike.%$searchTerm%,BACSI.TenBS.ilike.%$searchTerm%');
      }

      if (startDate != null) {
        query = query.gte('Ngayketoa', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('Ngayketoa', endDate.toIso8601String());
      }

      final response = await query.order('Ngayketoa', ascending: false);

      return (response as List).map((prescription) {
        final doctorData = prescription['BACSI'] as Map<String, dynamic>?;
        final patientData = prescription['BENHNHAN'] as Map<String, dynamic>?;
        return Prescription.fromJson({
          ...prescription,
          'doctor_name': doctorData?['TenBS'],
          'patient_name': patientData?['TenBN'],
        });
      }).toList();
    } catch (e) {
      print('Error searching prescriptions: $e');
      rethrow;
    }
  }
}
