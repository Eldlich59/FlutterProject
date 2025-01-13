class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? phone;
  final String? email;
  final DateTime startDate;
  final bool isActive;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.phone,
    this.email,
    required this.startDate,
    required this.isActive,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['MaBS'],
      name: json['TenBS'],
      specialty: json['ChuyenKhoa'],
      phone: json['SDT'],
      email: json['Email'],
      startDate: DateTime.parse(json['NgayVaoLam']),
      isActive: json['TrangThai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaBS': id,
      'TenBS': name,
      'ChuyenKhoa': specialty,
      'SDT': phone,
      'Email': email,
      'NgayVaoLam': startDate.toIso8601String(),
      'TrangThai': isActive,
    };
  }
}
