import 'package:clinic_management/services/inventory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'patient_service.dart';
import 'examination_service.dart';
import 'medicine_service.dart';
import 'prescription_service.dart';
import 'bill_service.dart';
import 'doctor_service.dart';
import 'specialty_service.dart';

class SupabaseService {
  final PatientService patientService;
  final ExaminationService examinationService;
  final MedicineService medicineService;
  final PrescriptionService prescriptionService;
  final BillService billService;
  final DoctorService doctorService;
  final SpecialtyService specialtyService;
  final InventoryService inventoryService;

  SupabaseService()
      : patientService = PatientService(Supabase.instance.client),
        examinationService = ExaminationService(Supabase.instance.client),
        medicineService = MedicineService(Supabase.instance.client),
        prescriptionService = PrescriptionService(Supabase.instance.client),
        billService = BillService(Supabase.instance.client),
        doctorService = DoctorService(Supabase.instance.client),
        specialtyService = SpecialtyService(Supabase.instance.client),
        inventoryService = InventoryService(Supabase.instance.client);
}
