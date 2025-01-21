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

  // Update color constants
  static const Color primaryColor = Color(0xFFFFB300); // Amber 700
  static const Color secondaryColor = Color(0xFFFFC107); // Amber 500
  static const Color backgroundColor = Color(0xFFFFF3E0); // Orange 50
  static const Color cardColor = Colors.white;

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
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15), // Updated shadow color
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.search, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _patientSearchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
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
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedDate != null ? primaryColor : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Chọn ngày',
                      style: TextStyle(
                        color:
                            _selectedDate != null ? primaryColor : Colors.grey,
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: Colors.grey,
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _filterPrescriptions();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1), // Updated border color
      ),
      child: InkWell(
        onTap: () => _navigateToPrescriptionDetails(prescription),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFFFDE7)
                    .withOpacity(0.5), // Very light yellow background
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.medical_information,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.patientName ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bác sĩ kê đơn: ${prescription.doctorName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy')
                          .format(prescription.prescriptionDate),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Chi tiết'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () => _navigateToPrescriptionDetails(prescription),
                  ),
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Sửa'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () =>
                        Future(() => _navigateToEditPrescription(prescription)),
                  ),
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Xóa'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () => Future(() => _confirmDelete(prescription)),
                  ),
                ],
              ),
            ],
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
        ),
        title: const Text(
          'Danh sách toa thuốc',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
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
          backgroundColor: primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Thêm toa thuốc',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
