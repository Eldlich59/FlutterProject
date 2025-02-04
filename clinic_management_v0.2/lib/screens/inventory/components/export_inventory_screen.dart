import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/inventory/inventory_receipt.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Load export receipts
      // TODO: Implement loading logic
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xuất kho'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReceiptList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExportDialog,
        child: const Icon(Icons.remove),
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
          child: ListTile(
            title: Text('Phiếu xuất kho #${receipt.id}'),
            subtitle:
                Text('Ngày xuất: ${dateFormat.format(receipt.importDate)}'),
            trailing: Text(currencyFormat.format(receipt.totalAmount)),
          ),
        );
      },
    );
  }

  void _showExportDialog() {
    // TODO: Implement export dialog
  }
}
