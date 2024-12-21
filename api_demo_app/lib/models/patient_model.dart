class Patient {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String medicalCondition;
  final String contactNumber;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.medicalCondition,
    required this.contactNumber,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Không rõ',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Khác',
      medicalCondition: json['medicalCondition'] ?? 'Chưa xác định',
      contactNumber: json['contactNumber'] ?? 'Không có',
    );
  }
}
