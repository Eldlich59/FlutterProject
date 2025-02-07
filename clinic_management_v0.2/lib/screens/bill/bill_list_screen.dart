import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/bill.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/services/bill_service.dart';
import 'package:clinic_management/screens/bill/bill_form_screen.dart';
import 'package:clinic_management/screens/bill/bill_details_sheet.dart';
import 'package:shimmer/shimmer.dart';

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

  // Update color constants with stronger shades
  final Color primaryColor = const Color(0xFF4FD1C5).withOpacity(0.9); // Stronger turquoise
  final Color secondaryColor = const Color(0xFFE6F7F5).withOpacity(0.7); // Clearer background
  final Color accentColor = const Color(0xFF38B2AC).withOpacity(0.95); // Deeper turquoise
  final Color textColor = const Color(0xFF2D3436).withOpacity(0.9);

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Trở về trang chủ',
          ),
        ),
        title: const Text(
          'Danh sách hóa đơn',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                      color: Colors.white, // Explicit white color
                      size: 28, // Slightly larger size
                    ),
            ),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white
                  .withOpacity(0.2), // Semi-transparent white background
              padding: const EdgeInsets.all(8),
            ),
            onPressed: _isLoading ? null : _loadBills,
            tooltip: 'Tải lại',
          ),
          const SizedBox(width: 12), // Increased spacing
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, accentColor],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              secondaryColor,
              Colors.white,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: _isLoading
            ? _buildShimmerLoading()
            : RefreshIndicator(
                color: primaryColor,
                onRefresh: _loadBills,
                child: _bills.isEmpty ? _buildEmptyState() : _buildBillsList(),
              ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có hóa đơn nào',
            style: TextStyle(
              fontSize: 24,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tạo hóa đơn mới ngay bây giờ',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bills.length,
      itemBuilder: (context, index) {
        final bill = _bills[index];
        return _buildAnimatedBillCard(bill, index);
      },
    );
  }

  Widget _buildAnimatedBillCard(Bill bill, int index) {
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
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
                      secondaryColor.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildBillContent(bill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillContent(Bill bill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    accentColor.withOpacity(0.1)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Mã hóa đơn #${_formatBillId(bill.id)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
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
        const SizedBox(height: 16),
        _buildInfoRow(Icons.person_outline, bill.patientName, accentColor),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.calendar_today,
          DateFormat('dd/MM/yyyy').format(bill.saleDate),
          Colors.grey.shade600,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.payment,
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
              .format(bill.totalCost),
          Colors.green.shade600,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color,
      {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FadeTransition(
        opacity: _fabOpacityAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToCreateBill(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Tạo hóa đơn',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          elevation: 4,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
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
