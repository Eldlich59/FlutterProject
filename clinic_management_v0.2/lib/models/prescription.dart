import 'package:clinic_management/models/medicine.dart';

class Prescription {
  final String id;
  final String doctorId;
  final DateTime prescriptionDate;
  final String? patientId; // Make nullable
  final String? examId; // Make nullable
  final List<PrescriptionDetail> details;
  final String? doctorName;

  Prescription({
    required this.id,
    required this.doctorId,
    required this.prescriptionDate,
    this.patientId, // Update constructor
    this.examId, // Update constructor
    this.details = const [],
    this.doctorName,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['MaToa'].toString(), // Convert to String if needed
      doctorId: json['MaBS'] ?? '', // Provide default value
      prescriptionDate: DateTime.parse(json['Ngayketoa']),
      patientId: json['MaBN']?.toString(), // Make nullable and convert
      examId: json['MaPK']?.toString(), // Make nullable and convert
      doctorName: json['doctor_name']?.toString() ?? 'Không xác định',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaToa': id,
      'Bsketoa': doctorId,
      'Ngayketoa': prescriptionDate.toIso8601String(),
      'MaBN': patientId,
      'MaPK': examId,
    };
  }
}

class PrescriptionDetail {
  final String prescriptionId;
  final String medicineId;
  final int quantity;
  final String usage;
  final Medicine? medicine;

  PrescriptionDetail({
    required this.prescriptionId,
    required this.medicineId,
    required this.quantity,
    required this.usage,
    this.medicine,
  });

  factory PrescriptionDetail.fromJson(Map<String, dynamic> json) {
    final medicineId = json['MaThuoc'];
    return PrescriptionDetail(
      prescriptionId: (json['MaToa']?.toString() ?? '').trim(),
      medicineId: medicineId != null ? medicineId.toString().trim() : '',
      quantity: json['Sluong'] is String
          ? int.tryParse(json['Sluong']) ?? 0
          : json['Sluong'] ?? 0,
      usage: (json['Cdung']?.toString() ?? '').trim(),
      medicine: json['thuoc'] != null ? Medicine.fromJson(json['thuoc']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaToa': prescriptionId,
      'MaThuoc': int.tryParse(medicineId) ?? medicineId,
      'Sluong': quantity,
      'Cdung': usage,
    };
  }
}
