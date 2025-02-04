import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/inventory/inventory_receipt.dart';
import '../../../models/inventory/supplier.dart';
import '../../../models/inventory/medicine.dart';
import '../../../services/inventory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImportInventoryScreen extends StatefulWidget {
  const ImportInventoryScreen({super.key});

  @override
  State<ImportInventoryScreen> createState() => _ImportInventoryScreenState();
}

class _ImportInventoryScreenState extends State<ImportInventoryScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final dateFormat = DateFormat('dd/MM/yyyy');
  List<InventoryReceipt>? importReceipts;
  bool isLoading = true;
  List<Supplier> suppliers = [];
  Supplier? selectedSupplier;
  final _inventoryService = InventoryService(Supabase.instance.client);
  List<Medicine> medicines = [];
  final List<Map<String, dynamic>> selectedItems = [];
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSuppliers();
    _loadMedicines();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final receiptsData = await _inventoryService.getInventoryReceipts();
      if (!mounted) return;
      setState(() {
        importReceipts = receiptsData
            .map((data) => InventoryReceipt.fromJson(data))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách phiếu nhập: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadSuppliers() async {
    if (!mounted) return;
    try {
      final suppliersData = await _inventoryService.getSuppliers();
      if (!mounted) return;
      setState(() {
        suppliers =
            suppliersData.map((data) => Supplier.fromJson(data)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách nhà cung cấp: $e')),
      );
    }
  }

  Future<void> _loadMedicines() async {
    if (!mounted) return;
    try {
      final medicinesData = await _inventoryService.getInventoryStatus();
      if (!mounted) return;
      setState(() {
        medicines =
            medicinesData.map((data) => Medicine.fromJson(data)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách thuốc: $e')),
      );
    }
  }

  String _formatId(String id) {
    return id.length > 6 ? '${id.substring(0, 6)}...' : id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập kho'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReceiptList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImportDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReceiptList() {
    if (importReceipts == null || importReceipts!.isEmpty) {
      return const Center(child: Text('Không có phiếu nhập kho'));
    }

    return ListView.builder(
      itemCount: importReceipts!.length,
      itemBuilder: (context, index) {
        final receipt = importReceipts![index];
        return Card(
          child: ListTile(
            title: Text('Phiếu nhập kho #${_formatId(receipt.id)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày nhập: ${dateFormat.format(receipt.importDate)}'),
                if (receipt.supplierName != null)
                  Text('Nhà cung cấp: ${receipt.supplierName}'),
              ],
            ),
            trailing: Text(
              currencyFormat.format(receipt.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            onTap: () => _showReceiptDetails(receipt),
          ),
        );
      },
    );
  }

  void _showReceiptDetails(InventoryReceipt receipt) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết phiếu nhập #${_formatId(receipt.id)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ngày nhập: ${dateFormat.format(receipt.importDate)}'),
              if (receipt.supplierName != null)
                Text('Nhà cung cấp: ${receipt.supplierName}'),
              const Divider(),
              ...receipt.details.map((detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(detail.medicineName ?? 'Unknown'),
                        ),
                        Text(
                            '${detail.quantity} x ${currencyFormat.format(detail.unitPrice)}'),
                      ],
                    ),
                  )),
              const Divider(),
              Text(
                'Tổng tiền: ${currencyFormat.format(receipt.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (receipt.notes != null) Text('Ghi chú: ${receipt.notes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showEditDialog(receipt),
            child: const Text('Sửa'),
          ),
          TextButton(
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content:
                      const Text('Bạn có chắc chắn muốn xóa phiếu nhập này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Xóa'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await _inventoryService.deleteInventoryReceipt(receipt.id);
                  Navigator.of(context).pop(); // Close details dialog
                  _loadData(); // Refresh the list
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa phiếu nhập kho')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa phiếu nhập: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Xóa'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(InventoryReceipt receipt) {
    if (!mounted) return;
    final BuildContext dialogContext = context;

    selectedItems.clear();
    notesController.text = receipt.notes ?? '';
    selectedSupplier = suppliers.firstWhere(
      (s) => s.id == receipt.supplierId,
      orElse: () => suppliers.first,
    );

    // Convert receipt details to selectedItems format
    for (var detail in receipt.details) {
      selectedItems.add({
        'medicineId': detail.medicineId,
        'quantity': detail.quantity,
        'unitPrice': detail.unitPrice,
      });
    }

    showDialog(
      context: dialogContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Sửa phiếu nhập #${_formatId(receipt.id)}'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: _buildImportForm(setDialogState),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: _isFormValid()
                      ? () async {
                          try {
                            await _inventoryService.updateInventoryReceipt(
                              receipt.id,
                              selectedSupplier!.id,
                              selectedItems,
                              notesController.text.trim(),
                            );
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            Navigator.of(dialogContext)
                                .pop(); // Use stored context
                            await _loadData(); // Refresh the list
                            if (!mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Cập nhật phiếu nhập kho thành công'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      : null,
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMedicineItem(
      int index, Map<String, dynamic> item, StateSetter setDialogState) {
    final selectedMedicine = medicines.firstWhere(
      (m) => m.id == item['medicineId'],
      orElse: () => medicines.first,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thuốc ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      setDialogState(() => selectedItems.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Medicine>(
              value: selectedMedicine,
              decoration: const InputDecoration(
                labelText: 'Tên thuốc',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: medicines.map((medicine) {
                return DropdownMenuItem(
                  value: medicine,
                  child: Text(medicine.name),
                );
              }).toList(),
              onChanged: (value) => setDialogState(() {
                selectedItems[index]['medicineId'] = value?.id;
                selectedItems[index]['unitPrice'] = value?.price ?? 0;
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: item['quantity']?.toString(),
              decoration: InputDecoration(
                labelText: 'Số lượng',
                border: const OutlineInputBorder(),
                suffixText: selectedMedicine.unit,
                helperText: 'Nhập số lượng',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setDialogState(() {
                selectedItems[index]['quantity'] = int.tryParse(value) ?? 0;
              }),
            ),
            if (item['quantity'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Thành tiền: ${currencyFormat.format((item['quantity'] as int) * selectedMedicine.price)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportForm(StateSetter setDialogState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<Supplier>(
              value: selectedSupplier,
              hint: const Text('Chọn nhà cung cấp'),
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nhà cung cấp',
              ),
              items: suppliers.map((supplier) {
                return DropdownMenuItem(
                  value: supplier,
                  child: Text(supplier.name),
                );
              }).toList(),
              onChanged: (value) =>
                  setDialogState(() => selectedSupplier = value),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...selectedItems.asMap().entries.map((entry) {
          return _buildMedicineItem(entry.key, entry.value, setDialogState);
        }).toList(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setDialogState(() {
            selectedItems.add({
              'medicineId': medicines.first.id,
              'quantity': 0,
              'unitPrice': medicines.first.price,
            });
          }),
          icon: const Icon(Icons.add),
          label: const Text('Thêm thuốc'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            border: OutlineInputBorder(),
            hintText: 'Nhập ghi chú nếu có',
          ),
          maxLines: 2,
        ),
        if (selectedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Tổng tiền: ${currencyFormat.format(selectedItems.fold<double>(
                0,
                (sum, item) =>
                    sum +
                    (item['quantity'] as int) * (item['unitPrice'] as double),
              ))}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  void _showImportDialog() {
    if (!mounted) return;
    final BuildContext dialogContext = context;

    selectedItems.clear();
    notesController.clear();
    selectedSupplier = null;

    showDialog(
      context: dialogContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo phiếu nhập kho'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: _buildImportForm(setDialogState),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: _isFormValid()
                      ? () async {
                          try {
                            await _inventoryService.createInventoryReceipt(
                              selectedSupplier!.id,
                              selectedItems,
                              notesController.text.trim(),
                            );
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            await _loadData();
                            if (!mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Tạo phiếu nhập kho thành công'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      : null,
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isFormValid() {
    return selectedSupplier != null &&
        selectedItems.isNotEmpty &&
        selectedItems.every((item) =>
            item['medicineId'] != null && (item['quantity'] as int) > 0);
  }
}
