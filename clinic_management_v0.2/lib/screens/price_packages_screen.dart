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
        title: Text('Bảng Giá Dịch Vụ'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddPackageDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Chọn Chuyên Khoa Hiển Thị',
                border: OutlineInputBorder(),
              ),
              value: selectedSpecialtyId,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tất cả chuyên khoa'),
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
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final package = packages[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(package.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá: ${package.price.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text('Trạng thái:'),
                            Switch(
                              value: package.isActive,
                              onChanged: (bool value) =>
                                  _togglePackageStatus(package, value),
                              activeColor: Colors.green,
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
                      icon: Icon(Icons.more_vert),
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
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Chi tiết'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                final newPackage = PricePackage(
                  id: '', // Let the database generate the ID
                  name: nameController.text,
                  chuyenKhoaId: dialogSpecialtyId!,
                  price: double.parse(priceController.text),
                  description: descriptionController.text,
                  includedServices: servicesController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  createdAt: DateTime.now(),
                );
                await _packageService.createPackage(newPackage);
                if (!mounted) return;
                Navigator.pop(context);
                _loadPackages();
              } catch (e) {
                _showError('Lỗi khi tạo gói dịch vụ: $e');
              }
            },
            child: Text('Lưu'),
          ),
        ],
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  createdAt: package.createdAt,
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
        title: Text(package.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giá: ${package.price.toStringAsFixed(0)} VNĐ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Mô tả: ${package.description}'),
            SizedBox(height: 8),
            Text('Dịch vụ bao gồm:'),
            ...package.includedServices.map((service) => Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $service'),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
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
}
