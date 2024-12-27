import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../repositories/prescription_repository.dart';
import '../models/prescription.dart';

class PrescriptionProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final PrescriptionRepository repository;
  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  PrescriptionProvider({required this.repository});

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPrescriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _prescriptions = await repository.getAllPrescriptions();
    } catch (e) {
      _error = 'Không thể tải đơn thuốc: $e';
      _logger.e('Error loading prescriptions', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPrescription(Prescription prescription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.insertPrescription(prescription);
      await loadPrescriptions();
    } catch (e) {
      _error = 'Không thể thêm đơn thuốc: $e';
      _logger.e('Error adding prescription', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePrescription(Prescription prescription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedPrescription =
          await repository.updatePrescription(prescription);
      final index = _prescriptions.indexWhere((p) => p.id == prescription.id);
      if (index != -1) {
        _prescriptions[index] = updatedPrescription;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể cập nhật đơn thuốc: $e';
      _logger.e('Error updating prescription', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePrescription(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.deletePrescription(id);
      await loadPrescriptions();
    } catch (e) {
      _error = 'Không thể xóa đơn thuốc: $e';
      _logger.e('Error deleting prescription', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Prescription?> getPrescriptionById(String id) async {
    try {
      return await repository.getPrescriptionById(id);
    } catch (e) {
      _error = 'Không thể tìm thấy đơn thuốc: $e';
      _logger.e('Error fetching prescription', error: e);
      return null;
    }
  }

  Future<List<Prescription>> getPrescriptionsByPatientId(
      String patientId) async {
    try {
      return _prescriptions.where((p) => p.patientId == patientId).toList();
    } catch (e) {
      _error = 'Không thể lọc đơn thuốc: $e';
      _logger.e('Error filtering prescriptions', error: e);
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
