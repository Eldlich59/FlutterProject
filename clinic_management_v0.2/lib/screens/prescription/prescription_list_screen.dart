import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/prescription.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/prescription/prescription_form_screen.dart';
import 'package:clinic_management/screens/prescription/prescription_detail_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService().prescriptionService;
  List<Prescription> _prescriptions = [];
  List<Prescription> _filteredPrescriptions = [];
  bool _isLoading = true;

  // Add search controllers
  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _doctorSearchController = TextEditingController();
  DateTime? _selectedDate;

  // Update color scheme to golden theme
  static const Color primaryColor = Color(0xFFFFB300); // Amber 700
  static const Color secondaryColor = Color(0xFFFFC107); // Amber 500
  static const Color backgroundColor = Color(0xFFFFF8E1); // Amber 50
  static const Color accentColor = Color(0xFFFF8F00); // Amber 800
  static const Color cardShadowColor = Color(0x29FFB300); // Amber shadow

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _patientSearchController.dispose();
    _doctorSearchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Search field
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.search, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _patientSearchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm toa thuốc...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 15),
                        onChanged: (value) {
                          _doctorSearchController.text = value;
                          _filterPrescriptions();
                        },
                      ),
                    ),
                    if (_patientSearchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _patientSearchController.clear();
                          _doctorSearchController.clear();
                          _filterPrescriptions();
                        },
                      ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // Date picker
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: _selectedDate != null
                              ? primaryColor
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Chọn ngày',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? primaryColor
                                : Colors.grey[600],
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          color: Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                              _filterPrescriptions();
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterPrescriptions() {
    setState(() {
      _filteredPrescriptions = _prescriptions.where((prescription) {
        final searchText = _patientSearchController.text.toLowerCase();
        final patientMatch =
            prescription.patientName?.toLowerCase().contains(searchText) ??
                false;
        final doctorMatch =
            prescription.doctorName?.toLowerCase().contains(searchText) ??
                false;
        final dateMatch = _selectedDate == null ||
            DateFormat('yyyy-MM-dd').format(prescription.prescriptionDate) ==
                DateFormat('yyyy-MM-dd').format(_selectedDate!);

        return (patientMatch || doctorMatch) && dateMatch;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterPrescriptions();
      });
    }
  }

  Future<void> _loadPrescriptions() async {
    if (!mounted) return;

    try {
      print('Loading prescriptions...'); // Debug print
      setState(() => _isLoading = true);

      final prescriptions = await _supabaseService.getPrescriptions();
      print('Loaded ${prescriptions.length} prescriptions'); // Debug print

      if (!mounted) return;

      setState(() {
        _prescriptions = prescriptions;
        _filteredPrescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading prescriptions: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải danh sách toa thuốc: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPrescriptionList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredPrescriptions.isEmpty) {
      return Center(
        child: AnimationConfiguration.synchronized(
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined,
                      size: 70, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy toa thuốc nào',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _filteredPrescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _filteredPrescriptions[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildPrescriptionCard(prescription),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 4,
        shadowColor: cardShadowColor,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => _navigateToPrescriptionDetails(prescription),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFFF8E1).withOpacity(0.5),
                ],
                stops: const [0.3, 1.0],
              ),
              border: Border.all(
                color: primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.medical_information,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  'Mã: ${prescription.id.length > 6 ? "${prescription.id.substring(0, 6)}..." : prescription.id}',
                                  style: TextStyle(
                                    color: primaryColor.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  prescription.patientName ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.3,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medical_services,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'BS. ${prescription.doctorName}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    height: 1.3,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(prescription.prescriptionDate),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  height: 1.3,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12), // Increased spacing
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FutureBuilder<Map<String, dynamic>>(
                                future: SupabaseService()
                                    .prescriptionService
                                    .getPrescriptionExamination(
                                        prescription.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    );
                                  }

                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                        ),
                                      ),
                                      child: const Text(
                                        'Lỗi',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }

                                  final examData = snapshot.data!;
                                  final examInfo = examData['PHIEUKHAM']
                                      as Map<String, dynamic>?;
                                  final bool isDoctorActive =
                                      examInfo?['BACSI']?['TrangThai'] ?? false;
                                  final bool isSpecialtyActive =
                                      examInfo?['CHUYENKHOA']?['TrangThaiHD'] ??
                                          false;
                                  final bool isPackageActive =
                                      examInfo?['price_packages']
                                              ?['is_active'] ??
                                          false;
                                  final bool isValid = isDoctorActive &&
                                      isSpecialtyActive &&
                                      (examInfo?['price_packages'] == null ||
                                          isPackageActive);
                                  final String examId =
                                      examInfo?['MaPK']?.toString() ?? '';

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (examId.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.description_outlined,
                                                size: 14,
                                                color: Colors.blue.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Mã PK: ${examId.length > 6 ? "${examId.substring(0, 6)}..." : examId}',
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isValid
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isValid
                                                ? Colors.green.shade200
                                                : Colors.red.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isValid
                                                  ? Icons.check_circle_outline
                                                  : Icons.error_outline,
                                              size: 14,
                                              color: isValid
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isValid
                                                  ? 'Hợp lệ'
                                                  : 'Không hợp lệ',
                                              style: TextStyle(
                                                color: isValid
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng tiền thuốc:',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                            .format(prescription.medicineCost),
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                secondaryColor,
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),
        title: const Text(
          'Danh sách toa thuốc',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {
                _loadPrescriptions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Đang tải lại dữ liệu...'),
                      ],
                    ),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildPrescriptionList(),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddPrescription, // Change to use the method
          elevation: 4,
          backgroundColor: accentColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Thêm toa thuốc',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddPrescription() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const PrescriptionFormScreen(
              isEditing: false, // Explicitly set isEditing to false
            ),
          ),
        )
        .then((_) => _loadPrescriptions());
  }

  void _navigateToPrescriptionDetails(Prescription prescription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Hero(
          // Add Hero widget here instead
          tag: 'prescription-${prescription.id}',
          child: PrescriptionDetailScreen(prescription: prescription),
        ),
      ),
    );
  }

  void _navigateToEditPrescription(Prescription prescription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionFormScreen(
          prescription: prescription,
          isEditing: true,
        ),
      ),
    ).then((_) => _loadPrescriptions());
  }

  Future<void> _confirmDelete(Prescription prescription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa toa thuốc này không?'),
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
        await _supabaseService.deletePrescription(prescription.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa toa thuốc thành công')),
        );
        await _loadPrescriptions();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa toa thuốc: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
