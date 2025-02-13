import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/examination.dart';
import '../../services/supabase_service.dart';
import 'examination_form_screen.dart';
import '../prescription/prescription_form_screen.dart';
import '../examination/examination_details_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ExaminationListScreen extends StatefulWidget {
  final String?
      patientId; // Optional: to show examinations for specific patient

  const ExaminationListScreen({super.key, this.patientId});

  @override
  State<ExaminationListScreen> createState() => _ExaminationListScreenState();
}

class _ExaminationListScreenState extends State<ExaminationListScreen> {
  final _supabaseService = SupabaseService().examinationService;
  List<Examination> _examinations = [];
  bool _isLoading = true;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExaminations();
  }

  Future<void> _loadExaminations() async {
    try {
      setState(() => _isLoading = true);
      // Use the new method from SupabaseService
      final examinations =
          await _supabaseService.getExaminations(patientId: widget.patientId);
      if (mounted) {
        setState(() {
          _examinations = examinations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách khám: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Examination> get _filteredExaminations {
    if (_searchQuery.isEmpty) return _examinations;
    return _examinations.where((exam) {
      final searchLower = _searchQuery.toLowerCase();
      final examIdPrefix = exam.id.substring(0, 6).toLowerCase();

      // Fix: Properly handle nullable strings
      final patientNameMatch =
          exam.patientName?.toLowerCase().contains(searchLower) ?? false;
      final doctorNameMatch =
          exam.doctorName?.toLowerCase().contains(searchLower) ?? false;
      final diagnosisMatch = exam.diagnosis.toLowerCase().contains(searchLower);
      final idMatch = examIdPrefix.contains(searchLower);

      return patientNameMatch || diagnosisMatch || idMatch || doctorNameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Trở về trang chủ',
        ),
        title: Text(
          widget.patientId != null
              ? 'Lịch sử khám bệnh'
              : 'Danh sách phiếu khám',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                _loadExaminations();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang tải lại danh sách...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Tải lại danh sách',
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade500, Colors.blue.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            if (widget.patientId == null)
              AnimationConfiguration.synchronized(
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: -50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Tìm kiếm phiếu khám',
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide:
                                  BorderSide(color: Colors.blue.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                  color: Colors.blue.shade400, width: 2),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: const CircularProgressIndicator(),
                          );
                        },
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadExaminations,
                      child: _buildExaminationList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: FloatingActionButton.extended(
              onPressed: () => _navigateToExaminationForm(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Thêm phiếu khám',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              backgroundColor: Colors.blue.shade600,
              elevation: 4,
            ),
          );
        },
      ),
    );
  }

  Widget _buildExaminationList() {
    if (_filteredExaminations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 80,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có phiếu khám',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm phiếu khám mới bằng nút bên dưới',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredExaminations.length,
        itemBuilder: (context, index) {
          final examination = _filteredExaminations[index];
          // Thay đổi logic kiểm tra tính hợp lệ
          final bool isValid = examination.pricePackageId != null &&
              (examination.pricePackage?.isActive ?? false) &&
              examination.doctorId != null &&
              (examination.isDoctorActive ?? false) &&
              examination.specialtyId != null &&
              (examination.isSpecialtyActive ?? false);

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue.shade50],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => _showExaminationDetails(examination),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.medical_services,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'Mã phiếu khám: ${examination.id.substring(0, 6)}...',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isValid
                                                  ? Colors.green.shade100
                                                  : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isValid
                                                      ? Icons.check_circle
                                                      : Icons.error,
                                                  size: 14,
                                                  color: isValid
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isValid
                                                      ? 'Còn hiệu lực'
                                                      : 'Không hợp lệ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isValid
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'details':
                                        _showExaminationDetails(examination);
                                        break;
                                      case 'edit':
                                        _navigateToExaminationForm(
                                            context, examination);
                                        break;
                                      case 'delete':
                                        _confirmDelete(examination);
                                        break;
                                      case 'prescription':
                                        _navigateToPrescription(examination);
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Text('Xem chi tiết'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Sửa phiếu khám'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'prescription',
                                      child: Text('Kê đơn thuốc'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Xóa'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bệnh nhân: ${examination.patientName ?? 'Chưa có'}',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.medical_services,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bác sĩ: ${examination.doctorName ?? 'Chưa có'}',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _dateFormat
                                      .format(examination.examinationDate),
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.medical_information,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Chẩn đoán: ${examination.diagnosis}',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'Phí khám: ${_currencyFormat.format(examination.examinationFee)}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExaminationDetails(Examination examination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExaminationDetailsScreen(
          examination: examination,
          onExaminationUpdated: _loadExaminations,
        ),
      ),
    );
  }

  Future<void> _navigateToExaminationForm(BuildContext context,
      [Examination? examination]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExaminationFormScreen(
          patientId: widget.patientId,
          examination: examination,
        ),
      ),
    );

    if (result == true) {
      _loadExaminations();
    }
  }

  void _navigateToPrescription(Examination examination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionFormScreen(
          examination: examination,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Examination examination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa phiếu khám này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteExamination(examination.id);
        _loadExaminations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa phiếu khám')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }
}
