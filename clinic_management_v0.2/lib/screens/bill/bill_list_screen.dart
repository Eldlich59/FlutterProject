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

class _BillListScreenState extends State<BillListScreen>
    with TickerProviderStateMixin {
  final BillService _supabaseService = SupabaseService().billService;
  List<Bill> _bills = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Then initialize animations
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fabOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    // Start FAB animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
    _loadBills();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
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
        if (_animationController.status == AnimationStatus.forward) {
          _animationController.stop();
        }
        _animationController.reset();
        if (mounted) {
          _animationController.forward();
        }
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
    final jadeColor = Color(0xFF009688);
    final lightJadeColor = Color(0xFFE0F2F1);
    final accentJadeColor = Color(0xFF26A69A);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: jadeColor,
        title: const Text(
          'Danh sách hóa đơn',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
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
              Colors.white.withOpacity(0.9),
            ],
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: jadeColor,
                  strokeWidth: 3,
                ),
              )
            : RefreshIndicator(
                color: jadeColor,
                onRefresh: _loadBills,
                child: _bills.isEmpty
                    ? _buildEmptyState(jadeColor)
                    : _buildBillsList(
                        jadeColor, lightJadeColor, accentJadeColor),
              ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FadeTransition(
          opacity: _fabOpacityAnimation,
          child: FloatingActionButton.extended(
            onPressed: () => _navigateToCreateBill(context),
            icon: const Icon(Icons.add),
            label: const Text(
              'Tạo hóa đơn',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            elevation: 4,
            backgroundColor: accentJadeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color jadeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: jadeColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có hóa đơn nào',
            style: TextStyle(
              fontSize: 20,
              color: jadeColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList(
      Color jadeColor, Color lightJadeColor, Color accentJadeColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bills.length,
      itemBuilder: (context, index) {
        final bill = _bills[index];
        return _buildAnimatedBillCard(
          bill,
          index,
          jadeColor,
          lightJadeColor,
          accentJadeColor,
        );
      },
    );
  }

  Widget _buildAnimatedBillCard(Bill bill, int index, Color jadeColor,
      Color lightJadeColor, Color accentJadeColor) {
    final delay = index * 100;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (delay / 1000).clamp(0, 1),
          ((delay + 500) / 1000).clamp(0, 1),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (delay / 1000).clamp(0, 1),
          ((delay + 500) / 1000).clamp(0, 1),
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          child: Card(
            elevation: 4,
            shadowColor: jadeColor.withOpacity(0.3),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: () => _showBillDetails(context, bill),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      lightJadeColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBillContent(bill, jadeColor, accentJadeColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillContent(Bill bill, Color jadeColor, Color accentJadeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Hóa đơn #${_formatBillId(bill.id)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: jadeColor,
                  letterSpacing: 0.5,
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
                      Icon(Icons.visibility, color: Colors.black87),
                      SizedBox(width: 12),
                      Text('Chi tiết'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: const [
                      Icon(Icons.print, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('In hóa đơn'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
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
            Icon(Icons.person_outline, size: 20, color: accentJadeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bill.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd/MM/yyyy').format(bill.saleDate),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.payment, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
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

        // Ensure we have a valid ID before proceeding
        if (bill.id.isEmpty) {
          throw Exception('Mã hóa đơn không hợp lệ');
        }

        await _supabaseService.deleteBill(bill.id);
        await _loadBills(); // Refresh the list after deletion

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa hóa đơn thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
