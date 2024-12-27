import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../repositories/patient_repository.dart';
import '../models/patient.dart';

class PatientProvider extends ChangeNotifier {
  final PatientRepository repository;
  final _logger = Logger();
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _error;

  PatientProvider({required this.repository});

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await repository.getAllPatients();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Could not load patients: $e';
      _logger.e('Error loading patients', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPatient(Patient patient) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.addPatient(patient);
      await loadPatients();
    } catch (e) {
      _error = 'Không thể thêm bệnh nhân: $e';
      _logger.e('Error adding patient', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePatient(Patient patient) async {
    await repository.updatePatient(patient);
    await loadPatients();
  }

  Future<void> deletePatient(String id) async {
    await repository.deletePatient(id);
    await loadPatients();
  }

  Future<void> createPatient(Patient patient) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.createPatient(patient);
      await loadPatients(); // Refresh the patients list
    } catch (e) {
      _error = 'Không thể thêm bệnh nhân: $e';
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-throw to allow UI error handling
    }
  }
}
