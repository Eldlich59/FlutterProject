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
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final bills = await _supabaseService.getBills();
      if (mounted) {
        setState(() {
          _bills = bills;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bills: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách hóa đơn: $e')),
        );
      }
    }
  }

  String _formatBillId(String id) {
    return id.length > 6 ? '${id.substring(0, 6)}...' : id;
  }

  @override
  Widget build(BuildContext context) {
    final jadeColor = Color(0xFF40E0D0); // Turquoise jade color
    final lightJadeColor = Color(0xFFE0F2F1); // Light jade color

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: jadeColor,
        title: const Text(
          'Danh sách hóa đơn',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightJadeColor,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadBills,
                child: _bills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có hóa đơn nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bills.length,
                        itemBuilder: (context, index) {
                          final bill = _bills[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _showBillDetails(context, bill),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Hóa đơn #${_formatBillId(bill.id)}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton(
                                          icon: const Icon(Icons.more_vert),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'details',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.visibility,
                                                      color: Colors.black87),
                                                  SizedBox(width: 12),
                                                  Text('Chi tiết'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'print',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.print,
                                                      color: Colors.blue),
                                                  SizedBox(width: 12),
                                                  Text('In hóa đơn'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.delete,
                                                      color: Colors.red),
                                                  SizedBox(width: 12),
                                                  Text('Xóa',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'details') {
                                              _showBillDetails(context, bill);
                                            } else if (value == 'print') {
                                              _printBill(bill);
                                            } else if (value == 'delete') {
                                              _confirmDeleteBill(bill);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            bill.patientName,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(bill.saleDate),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.payment,
                                            size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          NumberFormat.currency(
                                                  locale: 'vi_VN', symbol: 'đ')
                                              .format(bill.totalCost),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateBill(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo hóa đơn'),
        elevation: 4,
        backgroundColor: jadeColor,
      ),
    );
  }

  Future<void> _navigateToCreateBill(BuildContext context) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BillFormScreen(),
        ),
      );

      if (result == true) {
        // Show success message and refresh
        await _loadBills(); // Refresh first

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo hóa đơn thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Navigation error: $e');
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
