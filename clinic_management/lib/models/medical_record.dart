class MedicalRecord {
  final String id; // MaPK
  final DateTime date; // NgayKham
  final String symptoms; // TrieuChung
  final String diagnosis; // ChuanDoan
  final double fee; // TienKham
  final String patientId; // MaBN

  MedicalRecord({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.diagnosis,
    required this.fee,
    required this.patientId,
  });

  Map<String, dynamic> toJson() => {
        'MaPK': id,
        'NgayKham': date.toIso8601String(),
        'TrieuChung': symptoms,
        'ChuanDoan': diagnosis,
        'TienKham': fee,
        'MaBN': patientId,
      };

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
        id: json['MaPK'],
        date: DateTime.parse(json['NgayKham']),
        symptoms: json['TrieuChung'] ?? '',
        diagnosis: json['ChuanDoan'] ?? '',
        fee: json['TienKham']?.toDouble() ?? 0.0,
        patientId: json['MaBN'],
      );

  MedicalRecord copyWith({
    String? id,
    DateTime? date,
    String? symptoms,
    String? diagnosis,
    double? fee,
    String? patientId,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      fee: fee ?? this.fee,
      patientId: patientId ?? this.patientId,
    );
  }

  @override
  String toString() {
    return 'MedicalRecord{id: $id, date: $date, symptoms: $symptoms, diagnosis: $diagnosis, fee: $fee, patientId: $patientId}';
  }
}
