import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/inventory/inventory_receipt.dart';
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
        title: const Text('Xuất kho',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
        elevation: 2,
        // Changed backgroundColor from blue to pink
        backgroundColor: Colors.pinkAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Changed gradient color (blue -> pink)
            colors: [Colors.pinkAccent.withOpacity(0.1), Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildReceiptList(),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showCreateExportDialog,
            heroTag: 'createExport',
            icon: const Icon(Icons.add),
            label: const Text('Tạo phiếu xuất'),
            // Changed backgroundColor from blue to pink
            backgroundColor: Colors.pinkAccent,
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            onPressed: _showExportDialog,
            heroTag: 'exportPrescription',
            icon: const Icon(Icons.local_pharmacy),
            label: const Text('Xuất theo đơn'),
            // Changed backgroundColor from green to pink
            backgroundColor: Colors.pinkAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptList() {
    if (exportReceipts == null || exportReceipts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có phiếu xuất kho',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: exportReceipts!.length,
      itemBuilder: (context, index) {
        final receipt = exportReceipts![index];
        final notes = receipt.notes;
        String displayNotes = notes ?? '';
        if (displayNotes.startsWith('Lý do: Xuất theo toa thuốc')) {
          // Extract and format prescription ID
          final parts = displayNotes.split('\n');
          if (parts.length > 1) {
            final prescriptionId = parts[1].replaceAll('Toa thuốc: ', '');
            displayNotes = 'Lý do: Xuất theo toa thuốc\n' 'Toa thuốc: ${prescriptionId.substring(0, 6)}...';
          }
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              'Phiếu xuất kho #${receipt.id.substring(0, 6)}...',
              // Changed title text color from blue to pink
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày xuất: ${dateFormat.format(receipt.importDate)}'),
                if (displayNotes.isNotEmpty)
                  Text(
                    displayNotes,
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
                      // Changed icon color from blue to pink
                      Icon(Icons.edit, color: Colors.pinkAccent),
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

                  return Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.medication_outlined,
                                color: Colors.pinkAccent,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chi tiết xuất kho',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final item = snapshot.data![index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: index < snapshot.data!.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['THUOC']['TenThuoc'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Đơn vị: ${item['THUOC']['DonVi'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'SL: ${item['SoLuong']}',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (snapshot.data!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tổng ${snapshot.data!.length} mặt hàng',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
      DateTime selectedDate =
          receipt.importDate; // Initialize with receipt date

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Changed icon color from blue to pink
                      const Icon(Icons.edit_note, color: Colors.pinkAccent, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sửa phiếu xuất kho #${receipt.id.substring(0, 6)}...',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thông tin chung',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Add Date Picker
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Ngày xuất kho'),
                                    subtitle:
                                        Text(dateFormat.format(selectedDate)),
                                    trailing: const Icon(Icons.calendar_today),
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null &&
                                          picked != selectedDate) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: reasonController,
                                    decoration: InputDecoration(
                                      labelText: 'Lý do xuất kho',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.description),
                                      filled: true,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: notesController,
                                    decoration: InputDecoration(
                                      labelText: 'Ghi chú',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.note),
                                      filled: true,
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Danh sách thuốc',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...selectedItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final medicine = medicines.firstWhere(
                              (m) => m['MaThuoc'] == item['medicineId'],
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              child: ExpansionTile(
                                title: Text(
                                  medicine['TenThuoc'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Số lượng: ${item['quantity'] ?? 0} ${medicine['DonVi'] ?? 'đơn vị'}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => setState(() {
                                    selectedItems.removeAt(index);
                                  }),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        DropdownButtonFormField(
                                          value: item['medicineId'],
                                          isExpanded: true, // Add this
                                          items: medicines.map((m) {
                                            return DropdownMenuItem(
                                              value: m['MaThuoc'],
                                              child: Text(
                                                m['TenThuoc'],
                                                overflow: TextOverflow
                                                    .ellipsis, // Add this
                                                style: const TextStyle(
                                                    fontSize: 14), // Add this
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) => setState(() {
                                            selectedItems[index]['medicineId'] =
                                                value;
                                            selectedItems[index]['quantity'] =
                                                0;
                                            selectedItems[index]['isValid'] =
                                                false;
                                          }),
                                          decoration: InputDecoration(
                                            labelText: 'Chọn thuốc',
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              // Add this
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          initialValue:
                                              item['quantity']?.toString(),
                                          decoration: InputDecoration(
                                            labelText: 'Số lượng',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            suffixText:
                                                medicine['DonVi'] ?? 'Đơn vị',
                                            helperText:
                                                'Tồn kho: ${medicine['SoLuongTon']} ${medicine['DonVi'] ?? 'đơn vị'}',
                                            errorText: (item['quantity'] ?? 0) >
                                                    medicine['SoLuongTon']
                                                ? 'Số lượng xuất không thể lớn hơn số lượng tồn'
                                                : null,
                                            filled: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) => setState(() {
                                            final quantity =
                                                int.tryParse(value) ?? 0;
                                            selectedItems[index]['quantity'] =
                                                quantity;
                                            selectedItems[index]['isValid'] =
                                                quantity > 0 &&
                                                    quantity <=
                                                        medicine['SoLuongTon'];
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ElevatedButton.icon(
                                onPressed: () => setState(() {
                                  selectedItems.add({
                                    'medicineId': medicines.first['MaThuoc'],
                                    'quantity': 0,
                                    'isValid': false,
                                  });
                                }),
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm thuốc'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (selectedItems.isEmpty ||
                                reasonController.text.isEmpty ||
                                !selectedItems
                                    .every((item) => item['isValid'] == true))
                            ? null
                            : () async {
                                try {
                                  await _inventoryService.updateInventoryExport(
                                    receipt.id,
                                    selectedItems,
                                    reasonController.text.trim(),
                                    notesController.text.trim(),
                                    selectedDate, // Add selected date
                                  );
                                  if (!mounted) return;
                                  Navigator.of(context).pop(true);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cập nhật'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 600, // Fixed width for better layout
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.pinkAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chi tiết xuất kho',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: exportReceipts!.length,
                    itemBuilder: (context, index) {
                      final receipt = exportReceipts![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            'Phiếu xuất kho #${receipt.id.substring(0, 6)}...',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(receipt.importDate),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          children: [
                            Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'Danh sách thuốc',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _inventoryService
                                        .getExportReceiptDetails(receipt.id),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Lỗi: ${snapshot.error}',
                                            style: const TextStyle(
                                                color: Colors.red),
                                          ),
                                        );
                                      }
                                      if (!snapshot.hasData) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      return Column(
                                        children: snapshot.data!.map((detail) {
                                          final medicine = detail['THUOC'];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.medication_outlined,
                                                  size: 20,
                                                  color: Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        medicine['TenThuoc'],
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Đơn vị: ${medicine['DonVi'] ?? 'N/A'}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    'SL: ${detail['SoLuong']}',
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pop(receipt),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Chọn xuất kho'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
        const SnackBar(
          content: Text('Đã xuất kho theo đơn thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh the list
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xuất theo đơn: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
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
      DateTime selectedDate = DateTime.now(); // Add selected date variable

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Changed icon color from blue to pink
                      const Icon(
                        Icons.add_box_outlined,
                        color: Colors.pinkAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tạo phiếu xuất kho',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thông tin chung',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null &&
                                          picked != selectedDate) {
                                        setState(() => selectedDate = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 20,
                                              color: Colors.blue[700]),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Ngày xuất kho',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                dateFormat.format(selectedDate),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: reasonController,
                                    decoration: InputDecoration(
                                      labelText: 'Lý do xuất kho',
                                      hintText: 'Nhập lý do xuất kho',
                                      prefixIcon: const Icon(Icons.description),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: notesController,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      labelText: 'Ghi chú',
                                      hintText: 'Nhập ghi chú (nếu có)',
                                      prefixIcon: const Icon(Icons.note),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Danh sách thuốc',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  selectedItems.add({
                                    'medicineId': medicines.first['MaThuoc'],
                                    'quantity': 0,
                                    'isValid': false,
                                  });
                                }),
                                icon: const Icon(Icons.add, color: Colors.pinkAccent),
                                label: const Text('Thêm thuốc'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...selectedItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final medicine = medicines.firstWhere(
                              (m) => m['MaThuoc'] == item['medicineId'],
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField(
                                            value: item['medicineId'],
                                            isExpanded: true, // Add this
                                            items: medicines.map((m) {
                                              return DropdownMenuItem(
                                                value: m['MaThuoc'],
                                                child: Text(
                                                  m['TenThuoc'],
                                                  overflow: TextOverflow
                                                      .ellipsis, // Add this
                                                  style: const TextStyle(
                                                      fontSize: 14), // Add this
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) => setState(() {
                                              selectedItems[index]
                                                  ['medicineId'] = value;
                                              selectedItems[index]['quantity'] =
                                                  0;
                                              selectedItems[index]['isValid'] =
                                                  false;
                                            }),
                                            decoration: InputDecoration(
                                              labelText: 'Chọn thuốc',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                // Add this
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          color: Colors.red,
                                          onPressed: () => setState(() {
                                            selectedItems.removeAt(index);
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue:
                                          item['quantity']?.toString(),
                                      decoration: InputDecoration(
                                        labelText: 'Số lượng',
                                        suffixText:
                                            medicine['DonVi'] ?? 'Đơn vị',
                                        helperText:
                                            'Tồn kho: ${medicine['SoLuongTon']} ${medicine['DonVi'] ?? 'đơn vị'}',
                                        errorText: (item['quantity'] ?? 0) >
                                                medicine['SoLuongTon']
                                            ? 'Số lượng xuất không thể lớn hơn số lượng tồn'
                                            : null,
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => setState(() {
                                        final quantity =
                                            int.tryParse(value) ?? 0;
                                        selectedItems[index]['quantity'] =
                                            quantity;
                                        selectedItems[index]['isValid'] =
                                            quantity > 0 &&
                                                quantity <=
                                                    medicine['SoLuongTon'];
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: (selectedItems.isEmpty ||
                                reasonController.text.isEmpty ||
                                !selectedItems
                                    .every((item) => item['isValid'] == true))
                            ? null
                            : () async {
                                try {
                                  await _inventoryService.createInventoryExport(
                                    selectedItems,
                                    reasonController.text.trim(),
                                    notesController.text.trim(),
                                    selectedDate,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Tạo phiếu xuất thành công')),
                                  );
                                  _loadData();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          // Changed backgroundColor from blue to pink
                          backgroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Lưu'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
