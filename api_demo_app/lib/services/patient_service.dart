import '../models/patient_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PatientService {
  static const String baseUrl =
      'https://raw.githubusercontent.com/Eldlich59/PatientAPI/refs/heads/main/patients.json';

  Future<List<Patient>> fetchPatients() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> body = json.decode(response.body);
        List<dynamic> patientsData = body['patients'];
        List<Patient> patients =
            patientsData.map((dynamic item) => Patient.fromJson(item)).toList();
        return patients;
      } else {
        throw Exception('Không thể tải danh sách bệnh nhân');
      }
    } catch (e) {
      print('Lỗi: $e');
      return _generateMockPatients();
    }
  }

  // Phương thức tạo dữ liệu mẫu khi không có kết nối API
  List<Patient> _generateMockPatients() {
    return [
      Patient(
        id: 0,
        name: 'No one',
        age: 00,
        gender: 'Unknown',
        medicalCondition: 'Unknown',
        contactNumber: 'UnDefined',
      ),
    ];
  }
}

/*class PatientService {
  // URL Mock Server
  static const String baseUrl =
      'https://6756a2e311ce847c992d860f.mockapi.io/patients';

  // Lấy danh sách bệnh nhân
  Future<List<Patient>> fetchPatients() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> patientsData = data['data'];
      return patientsData.map((json) => Patient.fromJson(json)).toList();
    } else {
      throw Exception('Tải danh sách bệnh nhân thất bại');
    }
  }

  // Thêm bệnh nhân mới
  Future<Patient> addPatient(Patient patient) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(patient.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Map<String, dynamic> data = json.decode(response.body);
      return Patient.fromJson(data['data']);
    } else {
      throw Exception('Thêm bệnh nhân thất bại');
    }
  }

  // Cập nhật thông tin bệnh nhân
  Future<Patient> updatePatient(Patient patient) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${patient.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(patient.toJson()),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return Patient.fromJson(data['data']);
    } else {
      throw Exception('Cập nhật bệnh nhân thất bại');
    }
  }

  // Xóa bệnh nhân
  Future<void> deletePatient(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Xóa bệnh nhân thất bại');
    }
  }
}

// Bổ sung phương thức toJson() cho model Patient
extension PatientExtension on Patient {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'medicalCondition': medicalCondition,
      'contactNumber': contactNumber,
    };
  }
}*/
