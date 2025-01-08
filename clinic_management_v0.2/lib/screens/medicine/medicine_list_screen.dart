import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medicine.dart';
import '../../services/supabase_service.dart';
import 'medicine_form_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  List<Medicine> _medicines = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      setState(() => _isLoading = true);
      print('Loading medicines...'); // Debug log

      final medicines = await _supabaseService.getMedicines();
      print('Loaded ${medicines.length} medicines'); // Debug log

      setState(() {
        _medicines = medicines;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading medicines: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Medicine> get _filteredMedicines {
    if (_searchQuery.isEmpty) return _medicines;
    final query = _searchQuery.toLowerCase();
    return _medicines.where((medicine) {
      return medicine.name.toLowerCase().contains(query) ||
          medicine.unit.toLowerCase().contains(query) ||
          medicine.price.toString().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuốc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedicines,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm thuốc',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadMedicines,
                    child: _buildMedicineList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToMedicineForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicineList() {
    if (_filteredMedicines.isEmpty) {
      return const Center(
        child: Text('Không có thuốc nào'),
      );
    }

    return ListView.builder(
      itemCount: _filteredMedicines.length,
      itemBuilder: (context, index) {
        final medicine = _filteredMedicines[index];
        final bool isExpired = medicine.expiryDate.isBefore(DateTime.now());
        final bool isNearExpiry = medicine.expiryDate
            .isBefore(DateTime.now().add(const Duration(days: 30)));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              medicine.name,
              style: TextStyle(
                color: isExpired ? Colors.red : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đơn vị: ${medicine.unit}'),
                Text('Giá: ${_currencyFormat.format(medicine.price)}'),
                Text(
                  'HSD: ${DateFormat('dd/MM/yyyy').format(medicine.expiryDate)}',
                  style: TextStyle(
                    color: isExpired
                        ? Colors.red
                        : isNearExpiry
                            ? Colors.orange
                            : null,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToMedicineForm(context, medicine),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(medicine),
                ),
              ],
            ),
            onTap: () => _showMedicineDetails(medicine),
          ),
        );
      },
    );
  }

  Future<void> _navigateToMedicineForm(BuildContext context,
      [Medicine? medicine]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineFormScreen(medicine: medicine),
      ),
    );

    if (result == true) {
      _loadMedicines();
    }
  }

  Future<void> _confirmDelete(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa thuốc ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteMedicine(medicine.id); // Remove int.parse
        _loadMedicines();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa thuốc')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showMedicineDetails(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medicine.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đơn vị: ${medicine.unit}'),
            Text('Giá: ${_currencyFormat.format(medicine.price)}'),
            Text(
                'Ngày sản xuất: ${DateFormat('dd/MM/yyyy').format(medicine.manufacturingDate)}'),
            Text(
                'Hạn sử dụng: ${DateFormat('dd/MM/yyyy').format(medicine.expiryDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
