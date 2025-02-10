import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/specialty.dart';
import '../models/price_package.dart';
import '../services/specialty_service.dart';
import '../services/price_package_service.dart';

class PricePackagesScreen extends StatefulWidget {
  const PricePackagesScreen({super.key});

  @override
  State<PricePackagesScreen> createState() => _PricePackagesScreenState();
}

class _PricePackagesScreenState extends State<PricePackagesScreen> {
  final SpecialtyService _specialtyService =
      SpecialtyService(Supabase.instance.client);
  final PricePackageService _packageService =
      PricePackageService(Supabase.instance.client);

  List<Specialty> specialties = [];
  List<PricePackage> packages = [];
  String? selectedSpecialtyId;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    _loadPackages();
  }

  Future<void> _loadSpecialties() async {
    try {
      final loadedSpecialties = await _specialtyService
          .getSpecialties(); // Changed from getAllSpecialties
      setState(() {
        specialties = loadedSpecialties;
      });
    } catch (e) {
      _showError('Error loading specialties: $e');
    }
  }

  Future<void> _loadPackages() async {
    try {
      final loadedPackages = selectedSpecialtyId != null
          ? await _packageService.getPackagesByChuyenKhoa(selectedSpecialtyId!)
          : await _packageService.getAllPackages();
      setState(() {
        packages = loadedPackages;
      });
    } catch (e) {
      _showError('Error loading packages: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Giá Dịch Vụ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.shade50,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPackageDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Bảng Mới'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Chọn Chuyên Khoa',
                labelStyle: TextStyle(color: Colors.pink.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.pink.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.pink.shade200),
                ),
                filled: true,
                fillColor: Colors.pink.shade50,
                prefixIcon: const Icon(Icons.local_hospital),
              ),
              value: selectedSpecialtyId,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tất cả chuyên khoa',
                      style: TextStyle(color: Colors.pink.shade700)),
                ),
                ...specialties.map((specialty) {
                  return DropdownMenuItem<String>(
                    value: specialty.id,
                    child: Text(specialty.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSpecialtyId = value;
                  _loadPackages();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final package = packages[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: package.isActive
                          ? Colors.green.shade200
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      package.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.monetization_on,
                                color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${package.price.toStringAsFixed(0)} VNĐ',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Trạng thái:'),
                            Switch(
                              value: package.isActive,
                              onChanged: (bool value) =>
                                  _togglePackageStatus(package, value),
                              activeColor: Colors.green,
                              activeTrackColor: Colors.green.shade100,
                            ),
                            Text(
                              package.isActive
                                  ? "Đang hoạt động"
                                  : "Ngưng hoạt động",
                              style: TextStyle(
                                color: package.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: ListTile(
                            leading: const Icon(Icons.info_outline, size: 20),
                            title: const Text('Chi tiết'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: const Icon(Icons.edit, size: 20),
                            title: const Text('Chỉnh sửa'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            title: const Text('Xóa',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditPackageDialog(package);
                            break;
                          case 'delete':
                            _confirmDelete(package);
                            break;
                          case 'details':
                            _showPackageDetails(package);
                            break;
                        }
                      },
                    ),
                    onTap: () => _showPackageDetails(package),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPackageDialog() async {
    if (specialties.isEmpty) {
      _showError('Vui lòng chờ danh sách chuyên khoa được tải');
      return;
    }

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final servicesController = TextEditingController();
    String? dialogSpecialtyId = selectedSpecialtyId;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Thêm Gói Dịch Vụ Mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Chuyên Khoa',
                    border: OutlineInputBorder(),
                  ),
                  value: dialogSpecialtyId,
                  items: specialties.map((specialty) {
                    return DropdownMenuItem(
                      value: specialty.id,
                      child: Text(specialty.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    dialogSpecialtyId = value;
                  },
                ),
                SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên Gói Dịch Vụ',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VNĐ)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: servicesController,
                  decoration: InputDecoration(
                    labelText: 'Dịch vụ bao gồm (phân cách bằng dấu phẩy)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 8),
                ListTile(
                  title: Text('Ngày tạo:'),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(
                      selectedDate,
                      (date) => setState(() => selectedDate = date),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditPackageDialog(PricePackage package) async {
    final nameController = TextEditingController(text: package.name);
    final priceController =
        TextEditingController(text: package.price.toString());
    final descriptionController =
        TextEditingController(text: package.description);
    final servicesController =
        TextEditingController(text: package.includedServices.join(', '));
    String? dialogSpecialtyId = package.chuyenKhoaId;
    DateTime selectedDate = package.createdAt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Added StatefulBuilder to update date in dialog
        builder: (context, setState) => AlertDialog(
          title: Text('Chỉnh Sửa Gói Dịch Vụ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Chuyên Khoa',
                    border: OutlineInputBorder(),
                  ),
                  value: dialogSpecialtyId,
                  items: specialties.map((specialty) {
                    return DropdownMenuItem(
                      value: specialty.id,
                      child: Text(specialty.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    dialogSpecialtyId = value;
                  },
                ),
                SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên Gói Dịch Vụ',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Giá (VNĐ)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: servicesController,
                  decoration: InputDecoration(
                    labelText: 'Dịch vụ bao gồm (phân cách bằng dấu phẩy)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 8),
                ListTile(
                  title: Text('Ngày tạo:'),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(
                      selectedDate,
                      (date) => setState(() => selectedDate = date),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                if (dialogSpecialtyId == null ||
                    nameController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  _showError('Vui lòng điền đầy đủ thông tin bắt buộc');
                  return;
                }

                try {
                  final updatedPackage = PricePackage(
                    id: package.id,
                    name: nameController.text,
                    chuyenKhoaId: dialogSpecialtyId!,
                    price: double.parse(priceController.text),
                    description: descriptionController.text,
                    includedServices: servicesController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                    isActive: package.isActive,
                    createdAt: selectedDate, // Use selected date
                    updatedAt: DateTime.now(),
                  );
                  await _packageService.updatePackage(updatedPackage);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadPackages();
                } catch (e) {
                  _showError('Lỗi khi cập nhật gói dịch vụ: $e');
                }
              },
              child: Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PricePackage package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa vĩnh viễn gói dịch vụ này?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _packageService.deletePackage(package.id);
        _loadPackages();
      } catch (e) {
        _showError('Lỗi khi xóa gói dịch vụ: $e');
      }
    }
  }

  void _showPackageDetails(PricePackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.pink.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(package.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '${package.price.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Mô tả:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(package.description),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Dịch vụ bao gồm:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...package.includedServices.map((service) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(service)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Thông tin thời gian:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTimeInfoRow(
                Icons.calendar_today,
                'Ngày tạo:',
                _formatDate(package.createdAt),
              ),
              if (package.updatedAt != null) ...[
                const SizedBox(height: 4),
                _buildTimeInfoRow(
                  Icons.update,
                  'Cập nhật lần cuối:',
                  _formatDate(package.updatedAt!),
                ),
              ],
            ],
          ),
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

  // Add new method for toggling status
  Future<void> _togglePackageStatus(
      PricePackage package, bool newStatus) async {
    try {
      await _packageService.togglePackageStatus(package.id, newStatus);
      _loadPackages(); // Reload to update UI
    } catch (e) {
      _showError('Lỗi khi thay đổi trạng thái: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(
      DateTime initialDate, Function(DateTime) onSelect) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      // Preserve the original time when updating the date
      final newDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        initialDate.hour,
        initialDate.minute,
      );
      onSelect(newDate);
    }
  }

  Widget _buildTimeInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
