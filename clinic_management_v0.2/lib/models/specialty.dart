class Specialty {
  final String id;
  final String name;
  final bool isActive;
  final bool isSelfRegistration; // true = tự đăng ký, false = hợp đồng hỗ trợ

  Specialty({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isSelfRegistration,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['MaCK'],
      name: json['TenCK'],
      isActive:
          json['TrangThaiHD'] == null ? true : json['TrangThaiHD'] as bool,
      isSelfRegistration:
          json['HinhThucCP'] == null ? true : json['HinhThucCP'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaCK': id,
      'TenCK': name,
      'TrangThaiHD': isActive,
      'HinhThucCP': isSelfRegistration,
    };
  }
}
