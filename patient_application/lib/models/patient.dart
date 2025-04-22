import 'package:intl/intl.dart';

class Patient {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String bloodType;
  final String address;
  final String phoneNumber;
  final String email;
  final String? avatarUrl;
  final String? emergencyContact;
  final List<String>? allergies;
  final List<String>? chronicConditions;
  final double? height; // cm
  final double? weight; // kg

  Patient({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodType,
    required this.address,
    required this.phoneNumber,
    required this.email,
    this.avatarUrl,
    this.emergencyContact,
    this.allergies,
    this.chronicConditions,
    this.height,
    this.weight,
  });

  // Tính tuổi từ ngày sinh
  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Tính BMI nếu có chiều cao và cân nặng
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  // Định dạng ngày sinh
  String get formattedDateOfBirth {
    return DateFormat('dd/MM/yyyy').format(dateOfBirth);
  }

  // Factory constructor từ JSON
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      address: json['address'],
      dateOfBirth:
          json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'])
              : DateTime(1900, 1, 1), // Default date when null
      gender: json['gender'],
      bloodType: json['blood_type'],
      height:
          json['height']?.toDouble(), // Ensure proper conversion from integer
      weight:
          json['weight']?.toDouble(), // Ensure proper conversion from integer
      emergencyContact: json['emergency_contact'],
      avatarUrl: json['avatar_url'],
      allergies:
          json['allergies'] != null ? List<String>.from(json['allergies']) : [],
      chronicConditions:
          json['chronic_conditions'] != null
              ? List<String>.from(json['chronic_conditions'])
              : [],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phoneNumber,
      'address': address,
      'emergency_contact': emergencyContact,
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      // Các trường khác...
    };
  }

  // Tạo bản sao với các giá trị đã được cập nhật
  Patient copyWith({
    String? id,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? email,
    String? phoneNumber,
    String? address,
    String? emergencyContact,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicConditions,
    // Các trường khác...
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      // Các trường khác...
    );
  }
}
