import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/medicine.dart';
import '../../services/supabase_service.dart';
import 'medicine_form_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final _supabaseService = SupabaseService().medicineService;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  List<Medicine> _medicines = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _detailRowCount = 0;

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
      backgroundColor: Colors.red[50], // Lighter red background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.red[400],
        title: const Text(
          'Quản lý thuốc',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedicines,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Tìm kiếm thuốc',
                labelStyle: TextStyle(color: Colors.red[400]),
                prefixIcon: Icon(Icons.search, color: Colors.red[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.red[50],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red[400]!),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.red[400]))
                : RefreshIndicator(
                    onRefresh: _loadMedicines,
                    color: Colors.red[400],
                    child: _buildMedicineList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMedicineForm(null),
        backgroundColor: Colors.red[400],
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm thuốc',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          .animate()
          .scale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
          )
          .slideY(
            begin: 2,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuad,
          )
          .fadeIn(duration: const Duration(milliseconds: 300)),
    );
  }

  Widget _buildMedicineList() {
    if (_filteredMedicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400])
                .animate()
                .fade(duration: const Duration(milliseconds: 500))
                .scale(delay: const Duration(milliseconds: 200)),
            const SizedBox(height: 16),
            Text(
              'Không có thuốc nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredMedicines.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final medicine = _filteredMedicines[index];
        final bool isExpired = medicine.expiryDate.isBefore(DateTime.now());
        final bool isNearExpiry = medicine.expiryDate
            .isBefore(DateTime.now().add(const Duration(days: 30)));

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpired
                    ? Colors.red[300]!
                    : isNearExpiry
                        ? Colors.orange[300]!
                        : Colors.red[100]!,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isExpired
                    ? Colors.red[100]
                    : isNearExpiry
                        ? Colors.orange[100]
                        : Colors.red[50],
                child: Icon(
                  Icons.medication,
                  color: isExpired
                      ? Colors.red
                      : isNearExpiry
                          ? Colors.orange[700]
                          : Colors.red[400],
                  size: 24,
                ),
              ),
              title: Text(
                medicine.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.red : Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.medical_information,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(medicine.unit),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _currencyFormat.format(medicine.price),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: isExpired
                            ? Colors.red
                            : isNearExpiry
                                ? Colors.orange
                                : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HSD: ${DateFormat('dd/MM/yyyy').format(medicine.expiryDate)}',
                        style: TextStyle(
                          color: isExpired
                              ? Colors.red
                              : isNearExpiry
                                  ? Colors.orange
                                  : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showMedicineForm(medicine);
                      break;
                    case 'delete':
                      _confirmDelete(medicine);
                      break;
                    case 'details':
                      _showMedicineDetails(medicine);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: ListTile(
                      leading: Icon(Icons.info),
                      title: Text('Chi tiết'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Sửa'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Xóa'),
                      dense: true,
                    ),
                  ),
                ],
              ),
              onTap: () => _showMedicineDetails(medicine),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn(duration: const Duration(milliseconds: 500))
            .slideX(begin: 0.2, curve: Curves.easeOutQuad)
            .scale(begin: const Offset(0.8, 0.8));
      },
    );
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

  void _resetDetailRowCount() {
    _detailRowCount = 0;
  }

  void _showMedicineDetails(Medicine medicine) {
    _resetDetailRowCount();
    final bool isExpired = medicine.expiryDate.isBefore(DateTime.now());
    final bool isNearExpiry = medicine.expiryDate
        .isBefore(DateTime.now().add(const Duration(days: 30)));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.medication,
                        size: 35,
                        color: isExpired
                            ? Colors.red
                            : isNearExpiry
                                ? Colors.orange[700]
                                : Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      medicine.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isExpired || isNearExpiry)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              size: 16,
                              color: isExpired ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpired
                                  ? 'Đã hết hạn sử dụng'
                                  : 'Sắp hết hạn sử dụng',
                              style: TextStyle(
                                color:
                                    isExpired ? Colors.red : Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.medical_information,
                      'Đơn vị',
                      medicine.unit,
                      Colors.blue[700]!,
                    ),
                    _buildDetailRow(
                      Icons.attach_money,
                      'Giá',
                      _currencyFormat.format(medicine.price),
                      Colors.green[700]!,
                    ),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Ngày sản xuất',
                      DateFormat('dd/MM/yyyy')
                          .format(medicine.manufacturingDate),
                      Colors.purple[700]!,
                    ),
                    _buildDetailRow(
                      Icons.event,
                      'Hạn sử dụng',
                      DateFormat('dd/MM/yyyy').format(medicine.expiryDate),
                      isExpired
                          ? Colors.red
                          : isNearExpiry
                              ? Colors.orange[700]!
                              : Colors.teal[700]!,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ).animate().scale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 100 * _detailRowCount++),
          duration: const Duration(milliseconds: 200),
        );
  }

  void _showMedicineForm(Medicine? medicine) async {
    // Make method async
    final result = await showDialog<bool>(
      // Capture the dialog result
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MedicineFormDialog(medicine: medicine);
      },
    );

    if (result == true && mounted) {
      // Check if we need to refresh
      _loadMedicines(); // Reload the list if changes were made
    }
  }
}
