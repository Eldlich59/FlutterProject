import 'package:clinic_management/models/medicine.dart';

class Prescription {
  final String id;
  final String doctorName;
  final DateTime prescriptionDate;
  final String? patientId; // Make nullable
  final String? examId; // Make nullable
  final List<PrescriptionDetail> details;

  Prescription({
    required this.id,
    required this.doctorName,
    required this.prescriptionDate,
    this.patientId, // Update constructor
    this.examId, // Update constructor
    this.details = const [],
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['MaToa'].toString(), // Convert to String if needed
      doctorName: json['Bsketoa'] ?? '', // Provide default value
      prescriptionDate: DateTime.parse(json['Ngayketoa']),
      patientId: json['MaBN']?.toString(), // Make nullable and convert
      examId: json['MaPK']?.toString(), // Make nullable and convert
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaToa': id,
      'Bsketoa': doctorName,
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
    return PrescriptionDetail(
      prescriptionId: json['MaToa']?.toString() ?? '',
      medicineId: (json['MaThuoc'] ?? '').toString(), // Convert to string
      quantity: json['Sluong'] is String
          ? int.tryParse(json['Sluong']) ?? 0
          : json['Sluong'] ?? 0,
      usage: json['Cdung']?.toString() ?? '',
      medicine: json['thuoc'] != null ? Medicine.fromJson(json['thuoc']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaToa': prescriptionId,
      'MaThuoc': int.tryParse(medicineId) ??
          medicineId, // Convert back to int if possible
      'Sluong': quantity,
      'Cdung': usage,
    };
  }
}
