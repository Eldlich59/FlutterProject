class Prescription {
  final String id;
  final String doctorName;
  final DateTime prescriptionDate;
  final String patientId;
  final String medicalRecordId;
  final List<PrescriptionDetail> details;

  Prescription({
    required this.id,
    required this.doctorName,
    required this.prescriptionDate,
    required this.patientId,
    required this.medicalRecordId,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'MaToa': id,
      'Bsketoa': doctorName,
      'Ngayketoa': prescriptionDate.toIso8601String(),
      'MaBN': patientId,
      'MaPK': medicalRecordId,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['MaToa'] as String,
      doctorName: map['Bsketoa'] as String,
      prescriptionDate: DateTime.parse(map['Ngayketoa'] as String),
      patientId: map['MaBN'] as String,
      medicalRecordId: map['MaPK'] as String,
      details: (map['details'] as List?)
              ?.map((detail) => PrescriptionDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  // Alias for JSON serialization
  Map<String, dynamic> toJson() => toMap();
  factory Prescription.fromJson(Map<String, dynamic> json) =>
      Prescription.fromMap(json);

  Prescription copyWith({
    String? id,
    String? doctorName,
    DateTime? prescriptionDate,
    String? patientId,
    String? medicalRecordId,
    List<PrescriptionDetail>? details,
  }) =>
      Prescription(
        id: id ?? this.id,
        doctorName: doctorName ?? this.doctorName,
        prescriptionDate: prescriptionDate ?? this.prescriptionDate,
        patientId: patientId ?? this.patientId,
        medicalRecordId: medicalRecordId ?? this.medicalRecordId,
        details: details ?? this.details,
      );

  @override
  String toString() =>
      'Prescription{id: $id, doctorName: $doctorName, prescriptionDate: $prescriptionDate, patientId: $patientId, medicalRecordId: $medicalRecordId, details: $details}';
}

class PrescriptionDetail {
  final String medicineId;
  final int quantity;
  final String? usage;

  PrescriptionDetail({
    required this.medicineId,
    required this.quantity,
    this.usage,
  });

  Map<String, dynamic> toJson() {
    return {
      'MaThuoc': medicineId,
      'Sluong': quantity,
      'Cdung': usage,
    };
  }

  factory PrescriptionDetail.fromJson(Map<String, dynamic> json) {
    return PrescriptionDetail(
      medicineId: json['MaThuoc'] as String,
      quantity: json['Sluong'] as int,
      usage: json['Cdung'] as String?,
    );
  }

  PrescriptionDetail copyWith({
    String? medicineId,
    int? quantity,
    String? usage,
  }) =>
      PrescriptionDetail(
        medicineId: medicineId ?? this.medicineId,
        quantity: quantity ?? this.quantity,
        usage: usage ?? this.usage,
      );

  @override
  String toString() =>
      'PrescriptionDetail{medicineId: $medicineId, quantity: $quantity, usage: $usage}';
}
