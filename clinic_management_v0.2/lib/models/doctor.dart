class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? phone;
  final String? email;
  final DateTime dateOfBirth;
  final DateTime? startDate;
  final bool isActive;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.phone,
    this.email,
    required this.dateOfBirth,
    this.startDate,
    required this.isActive,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['MaBS']?.toString() ?? '', // Convert UUID to string
      name: json['TenBS'] ?? '',
      specialty: json['ChuyenKhoa'] ?? '',
      phone: json['SDT'],
      email: json['Email'],
      dateOfBirth: json['NgaySinh'] != null
          ? DateTime.parse(json['NgaySinh'])
          : DateTime.now(),
      startDate: json['NgayVaoLam'] != null
          ? DateTime.parse(json['NgayVaoLam'])
          : null,
      isActive: json['TrangThai'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'MaBS': id, // Only include ID if not empty
      'TenBS': name,
      'ChuyenKhoa': specialty,
      'SDT': phone,
      'Email': email,
      'NgaySinh': dateOfBirth.toIso8601String(),
      'NgayVaoLam': startDate?.toIso8601String(),
      'TrangThai': isActive,
    };
  }
}
