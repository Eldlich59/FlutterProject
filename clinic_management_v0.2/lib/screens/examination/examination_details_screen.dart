import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/examination.dart';
import '../prescription/prescription_form_screen.dart';
import 'examination_form_screen.dart';

class ExaminationDetailsScreen extends StatefulWidget {
  final Examination examination;
  final Function() onExaminationUpdated;

  const ExaminationDetailsScreen({
    super.key,
    required this.examination,
    required this.onExaminationUpdated,
  });

  @override
  _ExaminationDetailsScreenState createState() =>
      _ExaminationDetailsScreenState();
}

class _ExaminationDetailsScreenState extends State<ExaminationDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isExaminationValid {
    // Kiểm tra tính hợp lệ của phiếu khám
    final hasValidPackage = widget.examination.pricePackageId != null &&
        (widget.examination.pricePackage?.isActive ?? false);
    final hasValidDoctor = widget.examination.doctorId != null &&
        (widget.examination.isDoctorActive ?? false);
    final hasValidSpecialty = widget.examination.specialtyId != null &&
        (widget.examination.isSpecialtyActive ?? false);

    return hasValidPackage && hasValidDoctor && hasValidSpecialty;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Chi tiết phiếu khám',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.medical_services, color: Colors.white),
            onPressed: () => _navigateToPrescription(context),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Thêm container thông báo tính hợp lệ
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isExaminationValid
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isExaminationValid
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isExaminationValid
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _isExaminationValid
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isExaminationValid
                                      ? 'Phiếu khám hợp lệ'
                                      : 'Phiếu khám không hợp lệ do có dịch vụ không còn hoạt động',
                                  style: TextStyle(
                                    color: _isExaminationValid
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.95, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFF8F9FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(
                            'Thông tin chung',
                            [
                              _buildInfoRow('Bệnh nhân:',
                                  widget.examination.patientName ?? 'N/A'),
                              _buildServiceStatusRow(
                                  'Gói dịch vụ:',
                                  widget.examination.packageName ?? 'Không có',
                                  widget.examination.pricePackage?.isActive ??
                                      false),
                              _buildDoctorStatusRow(
                                  'Bác sĩ khám:',
                                  widget.examination.doctorName ??
                                      'Chưa phân công',
                                  widget.examination.isDoctorActive ?? false),
                              _buildSpecialtyStatusRow(
                                  'Chuyên khoa:',
                                  widget.examination.specialtyName ??
                                      'Chưa chọn chuyên khoa',
                                  widget.examination.isSpecialtyActive ??
                                      false),
                              _buildInfoRow(
                                  'Ngày khám:',
                                  dateFormat.format(
                                      widget.examination.examinationDate)),
                            ],
                            Icons.person,
                          ),
                          const SizedBox(height: 24),
                          _buildInfoSection(
                            'Chi tiết khám',
                            [
                              _buildInfoRow(
                                  'Triệu chứng:', widget.examination.symptoms),
                              _buildInfoRow(
                                  'Chẩn đoán:', widget.examination.diagnosis),
                            ],
                            Icons.medical_information,
                          ),
                          const SizedBox(height: 24),
                          _buildInfoSection(
                            'Chi phí',
                            [
                              _buildInfoRow(
                                  'Phí khám:',
                                  currencyFormat.format(
                                      widget.examination.examinationCost)),
                            ],
                            Icons.payment,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, IconData icon) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorStatusRow(String label, String value, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value == 'Chưa phân công' ? 'Chưa chọn bác sĩ' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        value == 'Chưa phân công' ? Colors.red : Colors.black87,
                    height: 1.3,
                    fontStyle: value == 'Chưa phân công'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              if (value != 'Chưa phân công')
                Chip(
                  label: Text(
                    isActive ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: isActive ? Colors.green : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyStatusRow(String label, String value, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value == 'Chưa chọn chuyên khoa'
                      ? 'Chưa chọn chuyên khoa'
                      : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value == 'Chưa chọn chuyên khoa'
                        ? Colors.red
                        : Colors.black87,
                    height: 1.3,
                    fontStyle: value == 'Chưa chọn chuyên khoa'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              if (value != 'Chưa chọn chuyên khoa')
                Chip(
                  label: Text(
                    isActive ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: isActive ? Colors.green : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatusRow(String label, String value, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value == 'Không có' ? 'Chưa chọn gói dịch vụ' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value == 'Không có' ? Colors.red : Colors.black87,
                    height: 1.3,
                    fontStyle: value == 'Không có'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              if (value != 'Không có')
                Chip(
                  label: Text(
                    isActive ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: isActive ? Colors.green : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExaminationFormScreen(examination: widget.examination),
      ),
    );

    if (result == true) {
      widget.onExaminationUpdated();
    }
  }

  void _navigateToPrescription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PrescriptionFormScreen(examination: widget.examination),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
