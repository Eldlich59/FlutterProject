import 'price_package.dart';

class Examination {
  final String id;
  final String patientId;
  final String? doctorId;
  final DateTime examinationDate;
  final String symptoms;
  final String diagnosis;
  final double examinationCost;
  final String? patientName;
  final String? doctorName; // Add this field
  final String? specialtyId; // Add this field
  final String? specialtyName; // Add this field
  final bool? isDoctorActive;
  final bool? isSpecialtyActive;
  final String? pricePackageId; // Add this field
  final String? packageName;
  final PricePackage? pricePackage; // Add this field

  Examination({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.examinationDate,
    required this.symptoms,
    required this.diagnosis,
    required this.examinationCost,
    this.patientName,
    this.doctorName, // Add this parameter
    this.specialtyId, // Add this parameter
    this.specialtyName, // Add this parameter
    this.isDoctorActive,
    this.isSpecialtyActive,
    this.pricePackageId, // Add this parameter
    this.packageName,
    this.pricePackage, // Add this parameter
  });

  factory Examination.fromJson(Map<String, dynamic> json) {
    try {
      Map<String, dynamic>? pricePackageData;
      if (json['price_packages'] != null) {
        if (json['price_packages'] is Map) {
          pricePackageData = Map<String, dynamic>.from(json['price_packages']);
        }
      }

      return Examination(
        id: json['MaPK']?.toString() ?? '',
        patientId: json['MaBN']?.toString() ?? '',
        doctorId: json['MaBS']?.toString(),
        examinationDate:
            DateTime.tryParse(json['NgayKham'] ?? '') ?? DateTime.now(),
        symptoms: json['TrieuChung'] ?? '',
        diagnosis: json['ChanDoan'] ?? '',
        examinationCost:
            double.tryParse(json['TienKham']?.toString() ?? '0') ?? 0.0,
        patientName: json['TenBN']?.toString(),
        doctorName: json['TenBS']?.toString(),
        specialtyId: json['MaCK']?.toString(),
        specialtyName: json['TenCK']?.toString(),
        isDoctorActive: json['BACSI']?['TrangThai'] ?? false,
        isSpecialtyActive: json['CHUYENKHOA']?['TrangThaiHD'] ?? false,
        pricePackageId: json['price_package_id']?.toString(),
        packageName: pricePackageData?['name']?.toString(),
        pricePackage: pricePackageData != null
            ? PricePackage.fromJson(pricePackageData)
            : null,
      );
    } catch (e) {
      print('Error parsing examination: $e');
      print('JSON data: $json');
      return Examination(
        id: json['MaPK']?.toString() ?? '',
        patientId: json['MaBN']?.toString() ?? '',
        examinationDate: DateTime.now(),
        symptoms: json['TrieuChung'] ?? '',
        diagnosis: json['ChanDoan'] ?? '',
        examinationCost: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'MaPK': id,
      'MaBN': patientId,
      if (doctorId != null) 'MaBS': doctorId,
      'NgayKham': examinationDate.toIso8601String(),
      'TrieuChung': symptoms,
      'ChanDoan': diagnosis,
      'TienKham': examinationCost,
      if (specialtyId != null) 'MaCK': specialtyId,
      if (pricePackageId != null) 'price_package_id': pricePackageId,
    };
  }

  bool isValidForPrescription() {
    // Kiểm tra các điều kiện để phiếu khám hợp lệ để kê đơn:
    // 1. Phiếu khám phải thuộc về bác sĩ đang hoạt động
    // 2. Phiếu khám phải thuộc chuyên khoa đang hoạt động
    // 3. Phiếu khám phải có gói dịch vụ đang hoạt động
    return isDoctorActive == true &&
        isSpecialtyActive == true &&
        pricePackage?.isActive == true;
  }
}
