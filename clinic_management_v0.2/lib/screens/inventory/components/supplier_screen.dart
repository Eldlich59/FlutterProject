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
  final _searchController = TextEditingController();
  List<Supplier>? _filteredSuppliers;

  // Thay thế late final bằng một biến thông thường
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterSuppliers);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chỉ khởi tạo nếu chưa được khởi tạo
    _scaffoldMessenger ??= ScaffoldMessenger.of(context);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final suppliersData = await _inventoryService.getSuppliers();
      print('Loaded suppliers: ${suppliersData.length}'); // Debug log

      if (!mounted) return;
      setState(() {
        suppliers =
            suppliersData.map((data) => Supplier.fromJson(data)).toList();
        // Khởi tạo _filteredSuppliers ngay khi có dữ liệu
        _filteredSuppliers = suppliers;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading suppliers: $e'); // Debug log
      if (!mounted) return;
      _scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSuppliers() {
    if (suppliers == null) return;

    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = suppliers;
      } else {
        _filteredSuppliers = suppliers!.where((supplier) {
          return supplier.name.toLowerCase().contains(query) ||
              (supplier.phone?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quản lý nhà cung cấp',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhà cung cấp...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue.shade100),
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tải dữ liệu...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : _buildSupplierList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSupplierDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhà cung cấp'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSupplierList() {
    final displayedSuppliers = _filteredSuppliers ?? suppliers;
    print('Displaying suppliers: ${displayedSuppliers?.length}'); // Debug log

    if (displayedSuppliers == null || displayedSuppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có nhà cung cấp nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // Thay thế AnimatedList bằng ListView.builder
      itemCount: displayedSuppliers.length,
      itemBuilder: (context, index) {
        final supplier = displayedSuppliers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEditSupplierDialog(supplier),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          supplier.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditSupplierDialog(supplier);
                              break;
                            case 'delete':
                              _showDeleteConfirmDialog(supplier);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text('Sửa'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Xóa'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  if (supplier.address != null && supplier.address!.isNotEmpty)
                    _buildInfoRow(
                        Icons.location_on_outlined, supplier.address!),
                  if (supplier.phone != null && supplier.phone!.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, supplier.phone!),
                  if (supplier.email != null && supplier.email!.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, supplier.email!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_business, color: Colors.blue.shade700),
                        const SizedBox(width: 16),
                        const Text(
                          'Thêm nhà cung cấp mới',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildEditTextField(
                      controller: nameController,
                      label: 'Tên nhà cung cấp',
                      icon: Icons.business,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      controller: addressController,
                      label: 'Địa chỉ',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      controller: phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Hủy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Vui lòng nhập tên nhà cung cấp'),
                                  backgroundColor: Colors.red,
                                ),
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
                              if (!mounted) return;
                              Navigator.pop(context);
                              await _loadData();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Thêm nhà cung cấp thành công'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Lỗi khi thêm nhà cung cấp: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Thêm mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      builder: (dialogContext) {
        final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.blue.shade700),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Chỉnh sửa ${supplier.name}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildEditTextField(
                      controller: nameController,
                      label: 'Tên nhà cung cấp',
                      icon: Icons.business,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      controller: addressController,
                      label: 'Địa chỉ',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      controller: phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Hủy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Vui lòng nhập tên nhà cung cấp'),
                                  backgroundColor: Colors.red,
                                ),
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
                              if (!mounted) return;
                              Navigator.pop(context);
                              await _loadData();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Cập nhật nhà cung cấp thành công'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Lỗi khi cập nhật nhà cung cấp: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu thay đổi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(Supplier supplier) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Xác nhận xóa'),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa nhà cung cấp "${supplier.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _inventoryService.deleteSupplier(supplier.id);
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  await _loadData();
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Xóa nhà cung cấp thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa nhà cung cấp: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
