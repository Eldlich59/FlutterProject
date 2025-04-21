class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorName;
  final String hospitalName;
  final String specialty;
  final DateTime visitDate;
  final String diagnosis;
  final String reason;
  final String conclusion;
  final String? instructions;
  final String? notes;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.hospitalName,
    required this.specialty,
    required this.visitDate,
    required this.diagnosis,
    required this.reason,
    required this.conclusion,
    this.instructions,
    this.notes,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patient_id'],
      doctorName: json['doctor_name'],
      hospitalName: json['hospital_name'],
      specialty: json['specialty'],
      visitDate: DateTime.parse(json['visit_date']),
      diagnosis: json['diagnosis'],
      reason: json['reason'],
      conclusion: json['conclusion'],
      instructions: json['instructions'],
      notes: json['notes'],
    );
  }
}
