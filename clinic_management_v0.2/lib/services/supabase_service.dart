import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_management/models/patient.dart';
import 'package:clinic_management/models/examination.dart';
import 'package:clinic_management/models/medicine.dart' as med;
import 'package:clinic_management/models/prescription.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // Patient operations
  Future<List<Patient>> getPatients() async {
    final response = await supabase
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
    await supabase.from('BENHNHAN').insert(patient.toJson());
  }

  Future<void> updatePatient(Patient patient) async {
    await supabase
        .from('BENHNHAN')
        .update(patient.toJson())
        .eq('MaBN', patient.id!);
  }

  Future<void> deletePatient(String id) async {
    await supabase.from('BENHNHAN').delete().eq('MaBN', id);
  }

  // Examination operations
  Future<List<Examination>> getExaminations({String? patientId}) async {
    var query = supabase
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
    await supabase.from('PHIEUKHAM').insert(examination.toJson());
  }

  Future<void> updateExamination(Examination examination) async {
    await supabase
        .from('PHIEUKHAM')
        .update(examination.toJson())
        .eq('MaPK', examination.id); // Changed from 'id' to 'MaPK'
  }

  Future<void> deleteExamination(String id) async {
    await supabase
        .from('PHIEUKHAM')
        .delete()
        .eq('MaPK', id); // Changed from 'id' to 'MaPK'
  }

  // Medicine operations
  Future<List<med.Medicine>> getMedicines() async {
    final response = await supabase.from('THUOC').select();
    return (response as List)
        .map((json) => med.Medicine.fromJson(json))
        .toList();
  }

  Future<void> addMedicine(med.Medicine medicine) async {
    final medicineJson = medicine.toJson();
    // Xóa MaThuoc khỏi JSON khi thêm mới để Supabase tự tạo ID
    medicineJson.remove('MaThuoc');
    await supabase.from('THUOC').insert(medicineJson);
  }

  Future<void> deleteMedicine(int id) async {
    await supabase.from('THUOC').delete().eq('MaThuoc', id);
  }

  Future<void> updateMedicine(med.Medicine medicine) async {
    await supabase
        .from('THUOC')
        .update(medicine.toJson())
        .eq('MaThuoc', medicine.id);
  }

  // Prescription operations
  Future<List<Prescription>> getPrescriptions() async {
    try {
      print('Fetching prescriptions from database...'); // Debug print

      final response = await supabase
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

      final response = await supabase.from('CHITIETTOATHUOC').select('''
            *,
            thuoc:THUOC (
              MaThuoc,
              TenThuoc,
              DVT,
              DonGia,
              SLTon
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

      final prescriptionResponse = await supabase
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
        await supabase.from('CHITIETTOATHUOC').insert(detailData);
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

    await supabase
        .from('TOATHUOC')
        .update(prescription)
        .eq('MaToa', prescriptionId);

    // Delete existing details
    await supabase.from('CHITIETTOATHUOC').delete().eq('MaToa', prescriptionId);

    // Insert new details
    for (final detail in details) {
      final detailData = {
        'MaToa': prescriptionId,
        'MaThuoc': detail.medicineId,
        'Sluong': detail.quantity,
        'Cdung': detail.usage,
      };

      await supabase.from('CHITIETTOATHUOC').insert(detailData);
    }
  }
}
