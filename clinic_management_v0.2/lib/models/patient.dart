class Patient {
  final String? id; // Make ID optional
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String address;
  final String phone;

  Patient({
    this.id, // Optional ID
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.phone,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    try {
      print('Converting JSON to Patient: $json');

      // Handle date parsing more robustly
      DateTime parsedDate;
      try {
        parsedDate = DateTime.parse(json['NgaySinh'].toString());
      } catch (e) {
        print('Error parsing date: ${json['NgaySinh']}');
        parsedDate = DateTime.now();
      }

      final patient = Patient(
        id: json['MaBN']?.toString(),
        name: json['TenBN']?.toString() ?? 'Unknown',
        dateOfBirth: parsedDate,
        gender: json['GioiTinh']?.toString() ?? 'Nam',
        address: json['DiaChi']?.toString() ?? '',
        phone: json['SDT']?.toString() ?? '',
      );

      print('Successfully created Patient object: ${patient.name}');
      return patient;
    } catch (e, stackTrace) {
      print('Error creating Patient from JSON: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      'TenBN': name,
      'NgaySinh': dateOfBirth.toIso8601String(),
      'GioiTinh': gender,
      'DiaChi': address,
      'SDT': phone,
    };

    // Only include MaBN if ID is not null
    if (id != null) {
      map['MaBN'] = id!;
    }

    return map;
  }
}
