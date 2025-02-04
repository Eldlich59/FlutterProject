import 'package:flutter/material.dart';
import '../../../models/inventory/supplier.dart';
import '../../../services/inventory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<Supplier>? suppliers;
  bool isLoading = true;
  final _inventoryService = InventoryService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final suppliersData = await _inventoryService.getSuppliers();
      suppliers = suppliersData.map((data) => Supplier.fromJson(data)).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhà cung cấp'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSupplierList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSupplierDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSupplierList() {
    if (suppliers == null || suppliers!.isEmpty) {
      return const Center(child: Text('Không có nhà cung cấp'));
    }

    return ListView.builder(
      itemCount: suppliers!.length,
      itemBuilder: (context, index) {
        final supplier = suppliers![index];
        return Card(
          child: ListTile(
            title: Text(supplier.name),
            subtitle: Text(supplier.address ?? 'Chưa có địa chỉ'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(supplier.phone ?? 'Chưa có SĐT'),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditSupplierDialog(supplier),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSupplierDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nhà cung cấp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Tên nhà cung cấp *'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng nhập tên nhà cung cấp')),
                );
                return;
              }

              try {
                await _inventoryService.addSupplier(
                  nameController.text,
                  addressController.text,
                  phoneController.text,
                  emailController.text,
                );
                Navigator.pop(context);
                _loadData(); // Reload the supplier list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thêm nhà cung cấp thành công')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi thêm nhà cung cấp: $e')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(Supplier supplier) {
    final nameController = TextEditingController(text: supplier.name);
    final addressController =
        TextEditingController(text: supplier.address ?? '');
    final phoneController = TextEditingController(text: supplier.phone ?? '');
    final emailController = TextEditingController(text: supplier.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa nhà cung cấp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Tên nhà cung cấp *'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng nhập tên nhà cung cấp')),
                );
                return;
              }

              try {
                await _inventoryService.updateSupplier(
                  supplier.id,
                  nameController.text,
                  addressController.text,
                  phoneController.text,
                  emailController.text,
                );
                Navigator.pop(context);
                _loadData(); // Reload the supplier list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Cập nhật nhà cung cấp thành công')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi cập nhật nhà cung cấp: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
