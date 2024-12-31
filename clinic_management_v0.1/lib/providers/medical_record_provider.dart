import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../repositories/medical_record_repository.dart';
import '../models/medical_record.dart';

class MedicalRecordProvider extends ChangeNotifier {
  final MedicalRecordRepository repository;
  final Logger _logger = Logger();
  List<MedicalRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  MedicalRecordProvider({required this.repository});

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await repository.getAllRecords();
    } catch (e) {
      _error = 'Không thể tải hồ sơ bệnh án: $e';
      _logger.e('Error loading medical records', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPatientRecords(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await repository.getPatientMedicalRecords(patientId);
    } catch (e) {
      _error = 'Không thể tải hồ sơ bệnh án của bệnh nhân: $e';
      _logger.e('Error loading patient medical records', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecord(MedicalRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.insertMedicalRecord(record);
      await loadRecords();
    } catch (e) {
      _error = 'Không thể thêm hồ sơ bệnh án: $e';
      _logger.e('Error adding medical record', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRecord(MedicalRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.updateMedicalRecord(record);
      await loadRecords();
    } catch (e) {
      _error = 'Không thể cập nhật hồ sơ bệnh án: $e';
      _logger.e('Error updating medical record', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.deleteMedicalRecord(id);
      await loadRecords();
    } catch (e) {
      _error = 'Không thể xóa hồ sơ bệnh án: $e';
      _logger.e('Error deleting medical record', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }
}
