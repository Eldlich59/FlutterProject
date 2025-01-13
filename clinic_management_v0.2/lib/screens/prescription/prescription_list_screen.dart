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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? const Center(child: Text('Chưa có toa thuốc nào'))
              : ListView.builder(
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = _prescriptions[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Bác sĩ: ${prescription.doctorId}'),
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
                              onTap: () =>
                                  _navigateToPrescriptionDetails(prescription),
                            ),
                            PopupMenuItem(
                              child: const ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Xóa'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: () =>
                                  Future(() => _confirmDelete(prescription)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
