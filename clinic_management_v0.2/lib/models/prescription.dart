import 'package:clinic_management/models/inventory/medicine.dart';

class Prescription {
  final String id;
  final String doctorId;
  final DateTime prescriptionDate;
  final String? patientId; // Make nullable
  final String? examId; // Make nullable
  final List<PrescriptionDetail> details;
  final String? doctorName;
  final String? patientName;
  final double medicineCost;

  Prescription({
    required this.id,
    required this.doctorId,
    required this.prescriptionDate,
    this.patientId, // Update constructor
    this.examId, // Update constructor
    this.details = const [],
    this.doctorName,
    this.patientName,
    required this.medicineCost,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['MaToa'].toString(), // Convert to String if needed
      doctorId: json['MaBS'] ?? '', // Provide default value
      prescriptionDate: DateTime.parse(json['Ngayketoa']),
      patientId: json['MaBN']?.toString(), // Make nullable and convert
      examId: json['MaPK']?.toString(), // Make nullable and convert
      doctorName: json['doctor_name']?.toString() ?? 'Không xác định',
      patientName: json['patient_name']?.toString() ?? 'Không xác định',
      medicineCost: (json['TienThuoc'] is int)
          ? (json['TienThuoc'] as int).toDouble()
          : (json['TienThuoc'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaToa': id,
      'Bsketoa': doctorId,
      'Ngayketoa': prescriptionDate.toIso8601String(),
      'MaBN': patientId,
      'MaPK': examId,
      'TienThuoc': medicineCost
    };
  }
}

class PrescriptionDetail {
  final String id;
  final String prescriptionId;
  final String medicineId;
  final int quantity;
  final String usage;
  final Medicine? medicine;

  PrescriptionDetail({
    required this.id,
    required this.prescriptionId,
    required this.medicineId,
    required this.quantity,
    required this.usage,
    this.medicine,
  });

  factory PrescriptionDetail.fromJson(Map<String, dynamic> json) {
    return PrescriptionDetail(
      id: json['id']?.toString() ?? '',
      prescriptionId: json['MaToa']?.toString() ?? '',
      medicineId: json['MaThuoc']?.toString() ?? '',
      quantity: json['Sluong'] ?? 0,
      usage: json['Cdung'] ?? '',
      medicine: json['thuoc'] != null ? Medicine.fromJson(json['thuoc']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'MaToa': prescriptionId,
      'MaThuoc': int.tryParse(medicineId) ?? medicineId,
      'Sluong': quantity,
      'Cdung': usage,
    };
  }
}
