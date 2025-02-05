import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/inventory/inventory_receipt.dart';
import '../../../services/prescription_service.dart';
import '../../../services/inventory_service.dart';

class ExportInventoryScreen extends StatefulWidget {
  const ExportInventoryScreen({super.key});

  @override
  State<ExportInventoryScreen> createState() => _ExportInventoryScreenState();
}

class _ExportInventoryScreenState extends State<ExportInventoryScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final dateFormat = DateFormat('dd/MM/yyyy');
  List<InventoryReceipt>? exportReceipts;
  bool isLoading = true;
  final PrescriptionService _prescriptionService =
      PrescriptionService(Supabase.instance.client);
  final InventoryService _inventoryService =
      InventoryService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final exports = await _inventoryService.getInventoryExports();

      exportReceipts = exports.map((data) {
        final exportDate = data['NgayXuat'] != null
            ? DateTime.parse(data['NgayXuat'])
            : DateTime.now();

        return InventoryReceipt(
          id: data['MaXuat'].toString(),
          importDate: exportDate,
          totalAmount: 0,
          supplierId: '',
          notes: data['LyDoXuat'] != null
              ? 'Lý do: ${data['LyDoXuat']}\n${data['GhiChu'] ?? ''}'
              : data['GhiChu'],
          details: [],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading export receipts: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xuất kho'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReceiptList(),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showCreateExportDialog,
            child: const Icon(Icons.add),
            heroTag: 'createExport',
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _showExportDialog,
            child: const Icon(Icons.local_pharmacy),
            heroTag: 'exportPrescription',
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptList() {
    if (exportReceipts == null || exportReceipts!.isEmpty) {
      return const Center(child: Text('Không có phiếu xuất kho'));
    }

    return ListView.builder(
      itemCount: exportReceipts!.length,
      itemBuilder: (context, index) {
        final receipt = exportReceipts![index];
        return Card(
          child: ExpansionTile(
            title: Text('Phiếu xuất kho #${receipt.id.substring(0, 6)}...'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày xuất: ${dateFormat.format(receipt.importDate)}'),
                if (receipt.notes?.isNotEmpty == true)
                  Text(
                    receipt.notes!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editExport(receipt);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(receipt);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa'),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _inventoryService.getExportReceiptDetails(receipt.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Lỗi: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: snapshot.data!.map((item) {
                      return ListTile(
                        dense: true,
                        title: Text(item['THUOC']['TenThuoc']),
                        subtitle:
                            Text('Đơn vị: ${item['THUOC']['DonVi'] ?? 'N/A'}'),
                        trailing: Text('Số lượng: ${item['SoLuong']}'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editExport(InventoryReceipt receipt) async {
    try {
      final medicines = await _inventoryService.getInventoryStatus();
      final details =
          await _inventoryService.getExportReceiptDetails(receipt.id);
      if (!mounted) return;

      final List<Map<String, dynamic>> selectedItems = details
          .map((detail) => {
                'medicineId': detail['MaThuoc'],
                'quantity': detail['SoLuong'],
                'isValid': true,
              })
          .toList();

      final reasonController = TextEditingController(
          text: receipt.notes?.split('\n').first.replaceAll('Lý do: ', ''));
      final notesController =
          TextEditingController(text: receipt.notes?.split('\n').last);

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Sửa phiếu xuất kho #${receipt.id.substring(0, 6)}...'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Lý do xuất kho',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ...selectedItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final medicine = medicines.firstWhere(
                      (m) => m['MaThuoc'] == item['medicineId'],
                    );

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField(
                                    value: item['medicineId'],
                                    items: medicines.map((m) {
                                      return DropdownMenuItem(
                                        value: m['MaThuoc'],
                                        child: Text(m['TenThuoc']),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() {
                                      selectedItems[index]['medicineId'] =
                                          value;
                                      selectedItems[index]['quantity'] = 0;
                                      selectedItems[index]['isValid'] = false;
                                    }),
                                    decoration: const InputDecoration(
                                      labelText: 'Chọn thuốc',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => setState(() {
                                    selectedItems.removeAt(index);
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: item['quantity']?.toString(),
                              decoration: InputDecoration(
                                labelText: 'Số lượng',
                                border: const OutlineInputBorder(),
                                suffixText: medicine['DonVi'] ?? 'Đơn vị',
                                helperText:
                                    'Tồn kho: ${medicine['SoLuongTon']} ${medicine['DonVi'] ?? 'đơn vị'}',
                                errorText: (item['quantity'] ?? 0) >
                                        medicine['SoLuongTon']
                                    ? 'Số lượng xuất không thể lớn hơn số lượng tồn'
                                    : null,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => setState(() {
                                final quantity = int.tryParse(value) ?? 0;
                                selectedItems[index]['quantity'] = quantity;
                                selectedItems[index]['isValid'] =
                                    quantity > 0 &&
                                        quantity <= medicine['SoLuongTon'];
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      selectedItems.add({
                        'medicineId': medicines.first['MaThuoc'],
                        'quantity': 0,
                        'isValid': false,
                      });
                    }),
                    child: const Text('Thêm thuốc'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: (selectedItems.isEmpty ||
                        reasonController.text.isEmpty ||
                        !selectedItems.every((item) => item['isValid'] == true))
                    ? null
                    : () async {
                        try {
                          await _inventoryService.updateInventoryExport(
                            receipt.id,
                            selectedItems,
                            reasonController.text.trim(),
                            notesController.text.trim(),
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      },
                child: const Text('Cập nhật'),
              ),
            ],
          ),
        ),
      );

      if (result == true) {
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật phiếu xuất thành công')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(InventoryReceipt receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa phiếu xuất kho #${receipt.id.substring(0, 6)}...?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _inventoryService.deleteInventoryExport(receipt.id);
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa phiếu xuất thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa phiếu xuất: $e')),
        );
      }
    }
  }

  void _showExportDialog() async {
    if (exportReceipts == null || exportReceipts!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có phiếu xuất cần xử lý')),
      );
      return;
    }

    final receipt = await showDialog<InventoryReceipt>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chi tiết xuất kho'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: exportReceipts!.length,
                    itemBuilder: (context, index) {
                      final receipt = exportReceipts![index];
                      return ExpansionTile(
                        title: Text(
                            'Phiếu xuất kho #${receipt.id.substring(0, 6)}...'),
                        subtitle: Text(dateFormat.format(receipt.importDate)),
                        trailing:
                            Text(currencyFormat.format(receipt.totalAmount)),
                        children: [
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _prescriptionService
                                .getPrescriptionMedicines(receipt.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text('Lỗi: ${snapshot.error}');
                              }
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }
                              return Column(
                                children: snapshot.data!.map((medicine) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(medicine['thuoc']['TenThuoc']),
                                    trailing: Text('SL: ${medicine['Sluong']}'),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(receipt),
                            child: const Text('Chọn xuất kho'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (receipt != null) {
      await _handleExport(receipt.id);
      await _loadData(); // Refresh the list
    }
  }

  Future<void> _handleExport(String exportId) async {
    try {
      // Get export details
      final exportDetails =
          await _inventoryService.getExportReceiptDetails(exportId);

      // Update stock quantities for each medicine in the export
      for (final detail in exportDetails) {
        final medicineId = detail['MaThuoc'];
        final quantity = detail['SoLuong'] as int;

        // Verify and update stock
        await _inventoryService.updateStockQuantity(medicineId, quantity);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xuất kho thành công')),
      );

      // Refresh the list
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xuất kho: $e')),
      );
    }
  }

  void _showCreateExportDialog() async {
    try {
      final medicines = await _inventoryService.getInventoryStatus();
      if (!mounted) return;

      final List<Map<String, dynamic>> selectedItems = [];
      final reasonController = TextEditingController();
      final notesController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Tạo phiếu xuất kho'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Lý do xuất kho',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập lý do xuất kho',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập lý do xuất kho';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập ghi chú (nếu có)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ...selectedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final medicine = medicines.firstWhere(
                        (m) => m['MaThuoc'] == item['medicineId'],
                      );

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField(
                                      value: item['medicineId'],
                                      items: medicines.map((m) {
                                        return DropdownMenuItem(
                                          value: m['MaThuoc'],
                                          child: Text(m['TenThuoc']),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() {
                                        selectedItems[index]['medicineId'] =
                                            value;
                                      }),
                                      decoration: const InputDecoration(
                                        labelText: 'Chọn thuốc',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => setState(() {
                                      selectedItems.removeAt(index);
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: item['quantity']?.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Số lượng',
                                  border: const OutlineInputBorder(),
                                  suffixText: medicine['DonVi'] ?? 'Đơn vị',
                                  helperText:
                                      'Tồn kho: ${medicine['SoLuongTon']} ${medicine['DonVi'] ?? 'đơn vị'}',
                                  errorText: (item['quantity'] ?? 0) >
                                          medicine['SoLuongTon']
                                      ? 'Số lượng xuất không thể lớn hơn số lượng tồn'
                                      : null,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {
                                  final quantity = int.tryParse(value) ?? 0;
                                  selectedItems[index]['quantity'] = quantity;
                                  selectedItems[index]['isValid'] =
                                      quantity > 0 &&
                                          quantity <= medicine['SoLuongTon'];
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        selectedItems.add({
                          'medicineId': medicines.first['MaThuoc'],
                          'quantity': 0,
                        });
                      }),
                      child: const Text('Thêm thuốc'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: (selectedItems.isEmpty ||
                        reasonController.text.isEmpty ||
                        !selectedItems.every((item) =>
                            item['quantity'] > 0 &&
                            item['quantity'] <=
                                medicines.firstWhere((m) =>
                                    m['MaThuoc'] ==
                                    item['medicineId'])['SoLuongTon']))
                    ? null
                    : () async {
                        try {
                          await _inventoryService.createInventoryExport(
                            selectedItems,
                            reasonController.text.trim(),
                            notesController.text.trim(),
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Tạo phiếu xuất thành công')),
                          );
                          _loadData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      },
                child: const Text('Xuất kho'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}
