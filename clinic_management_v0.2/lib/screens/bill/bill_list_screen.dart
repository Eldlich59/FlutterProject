import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/bill.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/services/bill_service.dart';
import 'package:clinic_management/screens/bill/bill_form_screen.dart';
import 'package:clinic_management/screens/bill/bill_details_sheet.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final BillService _supabaseService = SupabaseService().billService;
  List<Bill> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final bills = await _supabaseService.getBills();
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách hóa đơn: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách hóa đơn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBills,
              child: ListView.builder(
                itemCount: _bills.length,
                itemBuilder: (context, index) {
                  final bill = _bills[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text('BN: ${bill.patientName}'),
                      subtitle: Text(
                        'Ngày: ${DateFormat('dd/MM/yyyy').format(bill.saleDate)}\n'
                        'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(bill.totalCost)}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline),
                                SizedBox(width: 8),
                                Text('Chi tiết'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'print',
                            child: Row(
                              children: const [
                                Icon(Icons.print),
                                SizedBox(width: 8),
                                Text('In hóa đơn'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: const [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Xóa',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'details':
                              _showBillDetails(context, bill);
                              break;
                            case 'print':
                              _printBill(bill);
                              break;
                            case 'delete':
                              _confirmDeleteBill(bill);
                              break;
                          }
                        },
                      ),
                      onTap: () => _showBillDetails(context, bill),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateBill(context),
        tooltip: 'Tạo hóa đơn mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _navigateToCreateBill(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BillFormScreen(),
      ),
    );

    if (result == true) {
      // Refresh the bill list after creating a new bill
      setState(() => _isLoading = true);
      await _loadBills();
    }
  }

  void _printBill(Bill bill) {
    // Implement printing functionality
  }

  void _showBillDetails(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BillDetailsSheet(bill: bill),
      isScrollControlled: true, // Add this to make the sheet larger
    );
  }

  Future<void> _confirmDeleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa hóa đơn #${bill.id} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _supabaseService.deleteBill(bill.id);
        _loadBills(); // Refresh the list after deletion

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa hóa đơn thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa hóa đơn: $e')),
          );
        }
      }
    }
  }
}
