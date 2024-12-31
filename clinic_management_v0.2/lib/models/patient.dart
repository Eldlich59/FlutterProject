class Patient {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String address;
  final String phone;

  Patient({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.phone,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['MaBN'],
      name: json['TenBN'],
      dateOfBirth: DateTime.parse(json['NgaySinh']),
      gender: json['GioiTinh'],
      address: json['DiaChi'],
      phone: json['SDT'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaBN': id,
      'TenBN': name,
      'NgaySinh': dateOfBirth.toIso8601String(),
      'GioiTinh': gender,
      'DiaChi': address,
      'SDT': phone,
    };
  }
}
