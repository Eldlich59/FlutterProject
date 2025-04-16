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
      fullName: json['full_name'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      gender: json['gender'],
      bloodType: json['blood_type'],
      address: json['address'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      emergencyContact: json['emergency_contact'],
      allergies:
          json['allergies'] != null
              ? List<String>.from(json['allergies'])
              : null,
      chronicConditions:
          json['chronic_conditions'] != null
              ? List<String>.from(json['chronic_conditions'])
              : null,
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'blood_type': bloodType,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'avatar_url': avatarUrl,
      'emergency_contact': emergencyContact,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'height': height,
      'weight': weight,
    };
  }

  // Tạo bản sao với các giá trị đã được cập nhật
  Patient copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? address,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    String? emergencyContact,
    List<String>? allergies,
    List<String>? chronicConditions,
    double? height,
    double? weight,
  }) {
    return Patient(
      id: id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
