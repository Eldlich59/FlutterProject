import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../repositories/medicine_repository.dart';
import '../models/medicine.dart';

class MedicineProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final MedicineRepository repository;
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;

  MedicineProvider({required this.repository});

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMedicines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicines = await repository.getAllMedicines();
    } catch (e) {
      _error = 'Không thể tải danh sách thuốc: $e';
      _logger.e('Error loading medicines', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchMedicines(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicines = await repository.searchMedicines(query);
    } catch (e) {
      _error = 'Không thể tìm kiếm thuốc: $e';
      _logger.e('Error searching medicines', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.insertMedicine(medicine);
      await loadMedicines();
    } catch (e) {
      _error = 'Không thể thêm thuốc: $e';
      _logger.e('Error adding medicine', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.updateMedicine(medicine);
      await loadMedicines();
    } catch (e) {
      _error = 'Không thể cập nhật thuốc: $e';
      _logger.e('Error updating medicine', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedicine(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.deleteMedicine(id);
      await loadMedicines();
    } catch (e) {
      _error = 'Không thể xóa thuốc: $e';
      _logger.e('Error deleting medicine', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }
}
