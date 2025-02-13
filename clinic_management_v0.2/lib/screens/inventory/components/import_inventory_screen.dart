import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/inventory/inventory_receipt.dart';
import '../../../models/inventory/supplier.dart';
import '../../../models/inventory/medicine.dart';
import '../../../services/inventory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImportInventoryScreen extends StatefulWidget {
  const ImportInventoryScreen({super.key});

  // Add color constants
  static const primaryColor = Color(0xFF4CAF50); // Green
  static const secondaryColor = Color(0xFF81C784); // Light Green
  static const backgroundColor = Color(0xFFE8F5E9); // Very Light Green
  static const accentColor = Color(0xFFA5D6A7); // Pale Green

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
  DateTime selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSuppliers();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    notesController.dispose();
    super.dispose();
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

  Future<void> _selectDate(
      BuildContext context, StateSetter setDialogState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ImportInventoryScreen.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setDialogState(() {
        selectedDate = picked;
      });
    }
  }

  List<InventoryReceipt> _getFilteredReceipts() {
    if (_searchQuery.isEmpty) return importReceipts ?? [];
    return (importReceipts ?? []).where((receipt) {
      return receipt.id.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập kho'),
        elevation: 0,
        backgroundColor: ImportInventoryScreen.primaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phiếu nhập kho...',
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ImportInventoryScreen.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildReceiptList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImportDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu nhập'),
        backgroundColor: ImportInventoryScreen.primaryColor,
      ),
    );
  }

  Widget _buildReceiptList() {
    final filteredReceipts = _getFilteredReceipts();

    if (filteredReceipts.isEmpty) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Không có phiếu nhập kho'
                        : 'Không tìm thấy phiếu nhập kho phù hợp',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredReceipts.length,
      itemBuilder: (context, index) {
        final receipt = filteredReceipts[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showReceiptDetails(receipt),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long,
                                color: ImportInventoryScreen.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Phiếu #${_formatId(receipt.id)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            currencyFormat.format(receipt.totalAmount),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: ImportInventoryScreen.primaryColor,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(receipt.importDate),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.business, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            receipt.supplierName ?? 'Không có NCC',
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
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

  void _showReceiptDetails(InventoryReceipt receipt) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        backgroundColor: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ImportInventoryScreen.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chi tiết phiếu nhập #${_formatId(receipt.id)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Đóng',
              ),
            ],
          ),
        ),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Ngày nhập',
                        dateFormat.format(receipt.importDate),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.business,
                        'Nhà cung cấp',
                        receipt.supplierName ?? 'Không có',
                      ),
                      if (receipt.notes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.note,
                          'Ghi chú',
                          receipt.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách thuốc',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...receipt.details.map((detail) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                detail.medicineName ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Đơn giá: ${currencyFormat.format(detail.unitPrice)}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '× ${detail.quantity}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(
                                        detail.quantity * detail.unitPrice),
                                    style: TextStyle(
                                      color: ImportInventoryScreen.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ImportInventoryScreen.primaryColor.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color:
                            ImportInventoryScreen.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(receipt.totalAmount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ImportInventoryScreen.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(receipt),
                  icon: const Icon(Icons.edit),
                  label: const Text('Sửa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final currentContext = context;
                    final confirm = await showDialog<bool>(
                      context: currentContext,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: const Text(
                            'Bạn có chắc chắn muốn xóa phiếu nhập này?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(true),
                            icon: const Icon(Icons.delete),
                            label: const Text('Xóa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      try {
                        await _inventoryService
                            .deleteInventoryReceipt(receipt.id);
                        if (!mounted) return;
                        Navigator.of(currentContext).pop();
                        await _loadData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                              content: Text('Đã xóa phiếu nhập kho')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('Lỗi khi xóa phiếu nhập: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
    selectedDate = receipt.importDate; // Set date from receipt

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
                              selectedDate, // Add selected date
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
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
                tooltip: 'Xóa thuốc này',
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Medicine>(
            value: selectedMedicine,
            decoration: InputDecoration(
              labelText: 'Tên thuốc',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
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
          const SizedBox(height: 16),
          TextFormField(
            initialValue: item['quantity']?.toString(),
            decoration: InputDecoration(
              labelText: 'Số lượng',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixText: selectedMedicine.unit,
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => setDialogState(() {
              selectedItems[index]['quantity'] = int.tryParse(value) ?? 0;
            }),
          ),
          if (item['quantity'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ImportInventoryScreen.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thành tiền:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    currencyFormat.format(
                        (item['quantity'] as int) * selectedMedicine.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ImportInventoryScreen.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportForm(StateSetter setDialogState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionCard(
          title: 'Ngày nhập kho',
          child: _buildDatePicker(setDialogState),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Thông tin nhà cung cấp',
          child: _buildSupplierSelection(),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Danh sách thuốc',
          child: _buildMedicinesList(setDialogState),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Ghi chú',
          child: _buildNotesField(),
        ),
        if (selectedItems.isNotEmpty) _buildTotalAmount(),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ImportInventoryScreen.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDatePicker(StateSetter setDialogState) {
    return InkWell(
      onTap: () => _selectDate(context, setDialogState),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: ImportInventoryScreen.primaryColor.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: ImportInventoryScreen.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: ImportInventoryScreen.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierSelection() {
    return DropdownButtonFormField<Supplier>(
      value: selectedSupplier,
      hint: const Text('Chọn nhà cung cấp'),
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ImportInventoryScreen.primaryColor.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ImportInventoryScreen.primaryColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ImportInventoryScreen.primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(
          Icons.business,
          color: ImportInventoryScreen.primaryColor,
        ),
      ),
      items: suppliers.map((supplier) {
        return DropdownMenuItem(
          value: supplier,
          child: Text(supplier.name),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedSupplier = value),
    );
  }

  Widget _buildMedicinesList(StateSetter setDialogState) {
    return Column(
      children: [
        _buildAddMedicineButton(setDialogState),
        if (selectedItems.isEmpty) _buildEmptyMedicinesList(),
        ...selectedItems.asMap().entries.map((entry) =>
            _buildMedicineItem(entry.key, entry.value, setDialogState)),
      ],
    );
  }

  Widget _buildAddMedicineButton(StateSetter setDialogState) {
    return ElevatedButton.icon(
      onPressed: () => setDialogState(() {
        selectedItems.add({
          'medicineId': medicines.first.id,
          'quantity': 0,
          'unitPrice': medicines.first.price,
        });
      }),
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Thêm thuốc'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: ImportInventoryScreen.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildEmptyMedicinesList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có thuốc nào được thêm',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: notesController,
      decoration: InputDecoration(
        hintText: 'Nhập ghi chú nếu có...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ImportInventoryScreen.primaryColor.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ImportInventoryScreen.primaryColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ImportInventoryScreen.primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: 3,
    );
  }

  Widget _buildTotalAmount() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ImportInventoryScreen.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ImportInventoryScreen.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tổng tiền:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currencyFormat.format(selectedItems.fold<double>(
              0,
              (sum, item) =>
                  sum +
                  (item['quantity'] as int) * (item['unitPrice'] as double),
            )),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ImportInventoryScreen.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    if (!mounted) return;
    final BuildContext dialogContext = context;

    selectedItems.clear();
    notesController.clear();
    selectedSupplier = null;
    selectedDate = DateTime.now(); // Reset date to current

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
                              selectedDate, // Add selected date
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
        selectedItems.every((item) {
          final quantity = item['quantity'];
          // Check if quantity is not null and is a number greater than 0
          return item['medicineId'] != null &&
              quantity != null &&
              (quantity is int || quantity is String) &&
              (quantity is int
                  ? quantity > 0
                  : int.tryParse(quantity) != null && int.parse(quantity) > 0);
        }) &&
        !selectedDate.isAfter(DateTime.now()); // Simplified date validation
  }
}
