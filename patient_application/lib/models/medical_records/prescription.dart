class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      instructions: json['instructions'],
    );
  }
}

class Prescription {
  final String id;
  final String patientId;
  final String doctorName;
  final DateTime prescribedDate;
  final DateTime expiryDate;
  final String diagnosis;
  final List<Medication> medications;
  final String? notes;

  Prescription({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.prescribedDate,
    required this.expiryDate,
    required this.diagnosis,
    required this.medications,
    this.notes,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      patientId: json['patient_id'],
      doctorName: json['doctor_name'],
      prescribedDate: DateTime.parse(json['prescribed_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      diagnosis: json['diagnosis'],
      medications:
          (json['medications'] as List)
              .map((med) => Medication.fromJson(med))
              .toList(),
      notes: json['notes'],
    );
  }
}
