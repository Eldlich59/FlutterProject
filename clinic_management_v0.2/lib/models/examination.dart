class Examination {
  final String id;
  final String patientId;
  final DateTime examinationDate;
  final String symptoms;
  final String diagnosis;
  final double examinationFee;
  final String? patientName;

  Examination({
    required this.id,
    required this.patientId,
    required this.examinationDate,
    required this.symptoms,
    required this.diagnosis,
    required this.examinationFee,
    this.patientName,
  });

  factory Examination.fromJson(Map<String, dynamic> json) {
    return Examination(
      id: json['MaPK'] ?? '',
      patientId: json['MaBN'] ?? '',
      examinationDate: DateTime.parse(json['NgayKham']),
      symptoms: json['TrieuChung'] ?? '',
      diagnosis: json['ChanDoan'] ?? '',
      examinationFee: double.tryParse(json['TienKham'].toString()) ?? 0.0,
      patientName: json['TenBN'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'MaPK': id,
      'MaBN': patientId,
      'NgayKham': examinationDate.toIso8601String(),
      'TrieuChung': symptoms,
      'ChanDoan': diagnosis,
      'TienKham': examinationFee,
    };
  }
}
