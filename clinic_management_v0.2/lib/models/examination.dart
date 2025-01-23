class Examination {
  final String id;
  final String patientId;
  final String? doctorId;
  final DateTime examinationDate;
  final String symptoms;
  final String diagnosis;
  final double examinationFee;
  final String? patientName;
  final String? doctorName; // Add this field
  final String? specialtyId; // Add this field
  final String? specialtyName; // Add this field
  final bool? isDoctorActive;
  final bool? isSpecialtyActive;

  Examination({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.examinationDate,
    required this.symptoms,
    required this.diagnosis,
    required this.examinationFee,
    this.patientName,
    this.doctorName, // Add this parameter
    this.specialtyId, // Add this parameter
    this.specialtyName, // Add this parameter
    this.isDoctorActive,
    this.isSpecialtyActive,
  });

  factory Examination.fromJson(Map<String, dynamic> json) {
    return Examination(
      id: json['MaPK']?.toString() ?? '',
      patientId: json['MaBN']?.toString() ?? '',
      doctorId: json['MaBS']?.toString(),
      examinationDate:
          DateTime.tryParse(json['NgayKham'] ?? '') ?? DateTime.now(),
      symptoms: json['TrieuChung'] ?? '',
      diagnosis: json['ChanDoan'] ?? '',
      examinationFee: double.tryParse(json['TienKham'].toString()) ?? 0.0,
      patientName: json['TenBN']?.toString(),
      doctorName: json['TenBS']?.toString(), // Add this field mapping
      specialtyId: json['MaCK']?.toString(), // Add this field mapping
      specialtyName: json['TenCK']?.toString(), // Add this mapping
      isDoctorActive: json['BACSI']?['TrangThai'] ?? false,
      isSpecialtyActive: json['CHUYENKHOA']?['TrangThaiHD'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'MaPK': id,
      'MaBN': patientId,
      if (doctorId != null) 'MaBS': doctorId,
      'NgayKham': examinationDate.toIso8601String(),
      'TrieuChung': symptoms,
      'ChanDoan': diagnosis,
      'TienKham': examinationFee,
      if (specialtyId != null) 'MaCK': specialtyId, // Add this field
    };
  }
}
