import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/patient.dart';
import 'package:clinic_management/models/examination.dart';
import 'package:clinic_management/models/medicine.dart' as med;
import 'package:clinic_management/models/prescription.dart';
import 'package:clinic_management/models/bill.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // Patient operations
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

  // Examination operations
  Future<List<Examination>> getExaminations({String? patientId}) async {
    var query = _supabase
        .from('PHIEUKHAM')
        .select('*, BENHNHAN!inner(TenBN)'); // Join with BENHNHAN table

    if (patientId != null) {
      query = query.eq('MaBN', patientId);
    }

    final data = await query.order('NgayKham', ascending: false);

    return (data as List)
        .map((json) => Examination.fromJson({
              ...json,
              'TenBN': json['BENHNHAN']
                  ['TenBN'], // Map the patient name from the joined data
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

  // Medicine operations
  Future<List<med.Medicine>> getMedicines() async {
    try {
      final response = await _supabase
          .from('THUOC') // Changed from 'medicines' to 'THUOC'
          .select()
          .order('TenThuoc', ascending: true);

      print('Fetched medicines response: $response'); // Debug log

      return (response as List<dynamic>)
          .map((json) => med.Medicine.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching medicines: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> addMedicine(med.Medicine medicine) async {
    final medicineJson = medicine.toJson();
    // Xóa MaThuoc khỏi JSON khi thêm mới để Supabase tự tạo ID
    medicineJson.remove('MaThuoc');
    await _supabase.from('THUOC').insert(medicineJson);
  }

  Future<void> deleteMedicine(String id) async {
    // Change parameter type to String
    await _supabase.from('THUOC').delete().eq('MaThuoc', id);
  }

  Future<void> updateMedicine(med.Medicine medicine) async {
    await _supabase
        .from('THUOC')
        .update(medicine.toJson())
        .eq('MaThuoc', medicine.id);
  }

  // Prescription operations
  Future<List<Prescription>> getPrescriptions() async {
    try {
      print('Fetching prescriptions from database...'); // Debug print

      final response = await _supabase
          .from('TOATHUOC')
          .select()
          .order('Ngayketoa', ascending: false);

      print('Raw response: $response'); // Debug print

      if (response.isEmpty) {
        print('Response is empty'); // Debug print
        return [];
      }

      return (response as List).map((json) {
        try {
          return Prescription.fromJson(json);
        } catch (e) {
          print('Error parsing prescription: $e'); // Debug print
          print('Problematic JSON: $json'); // Debug print
          rethrow;
        }
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
    String doctorName,
    List<PrescriptionDetail> details, {
    required String patientId,
    required String examId,
  }) async {
    try {
      print('Creating prescription...'); // Debug print
      final prescription = {
        'Bsketoa': doctorName,
        'Ngayketoa': DateTime.now().toIso8601String(),
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
    String doctorName,
    List<PrescriptionDetail> details,
  ) async {
    final prescription = {
      'Bsketoa': doctorName,
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

  // Bill operations
  Future<List<Bill>> getBills() async {
    final response = await _supabase
        .from('HOADONTHUOC')
        .select()
        .order('Ngayban', ascending: false);

    if (response.isEmpty) {
      return [];
    }

    return (response as List).map((json) => Bill.fromJson(json)).toList();
  }

  Future<void> createBill({
    required String prescriptionId,
    required DateTime saleDate,
    required double medicineCost,
  }) async {
    await _supabase.from('HOADONTHUOC').insert({
      'MaToa': prescriptionId,
      'Ngayban': saleDate.toIso8601String(),
      'TienThuoc': medicineCost,
    });
  }

  Future<void> updateBill({
    required String id,
    required String prescriptionId,
    required DateTime saleDate,
    required double medicineCost,
  }) async {
    await _supabase.from('HOADONTHUOC').update({
      'MaToa': prescriptionId,
      'Ngayban': saleDate.toIso8601String(),
      'TienThuoc': medicineCost,
    }).eq('MaHD', id);
  }

  Future<void> deleteBill(String id) async {
    await _supabase.from('HOADONTHUOC').delete().eq('MaHD', id);
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
}
