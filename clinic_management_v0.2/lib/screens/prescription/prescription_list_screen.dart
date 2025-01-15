import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/prescription.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/prescription/prescription_form_screen.dart';
import 'package:clinic_management/screens/prescription/prescription_detail_screen.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  final _supabaseService = SupabaseService().prescriptionService;
  List<Prescription> _prescriptions = [];
  List<Prescription> _filteredPrescriptions = [];
  bool _isLoading = true;

  // Add search controllers
  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _doctorSearchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _doctorSearchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _patientSearchController,
              textAlign: TextAlign.center, // Center align the text
              decoration: InputDecoration(
                hintText: 'Tìm theo tên bệnh nhân/bác sĩ',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 15.0),
                hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                    fontSize: 20 // More faded hint text
                    ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _patientSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _patientSearchController.clear();
                          _doctorSearchController.clear();
                          _filterPrescriptions();
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
              onChanged: (value) {
                _doctorSearchController.text = value;
                _filterPrescriptions();
              },
            ),
          ),
          Container(
            height: 56,
            width: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
          InkWell(
            onTap: () => _selectDate(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: _selectedDate != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM').format(_selectedDate!),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách toa thuốc'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPrescriptions.isEmpty
                    ? const Center(child: Text('Không tìm thấy toa thuốc nào'))
                    : ListView.builder(
                        itemCount: _filteredPrescriptions.length,
                        itemBuilder: (context, index) {
                          final prescription = _filteredPrescriptions[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Bệnh nhân: ${prescription.patientName}'),
                                  Text('Bác sĩ: ${prescription.doctorName}'),
                                ],
                              ),
                              subtitle: Text(
                                'Ngày kê: ${DateFormat('dd/MM/yyyy').format(prescription.prescriptionDate)}',
                              ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const ListTile(
                                      leading: Icon(Icons.visibility),
                                      title: Text('Chi tiết'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () => _navigateToPrescriptionDetails(
                                        prescription),
                                  ),
                                  PopupMenuItem(
                                    child: const ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Sửa'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () => Future(() =>
                                        _navigateToEditPrescription(
                                            prescription)),
                                  ),
                                  PopupMenuItem(
                                    child: const ListTile(
                                      leading:
                                          Icon(Icons.delete, color: Colors.red),
                                      title: Text('Xóa'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () => Future(
                                        () => _confirmDelete(prescription)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPrescription,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddPrescription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrescriptionFormScreen(),
      ),
    ).then((_) => _loadPrescriptions());
  }

  void _navigateToPrescriptionDetails(Prescription prescription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PrescriptionDetailScreen(prescription: prescription),
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
