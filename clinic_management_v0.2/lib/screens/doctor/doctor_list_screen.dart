import 'package:flutter/material.dart';
import 'package:clinic_management/models/doctor.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/doctor/doctor_form.dart';
import 'package:clinic_management/screens/doctor/doctor_list_tile.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _supabaseService = SupabaseService().doctorService;
  List<Doctor> doctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      setState(() => isLoading = true);
      doctors = await _supabaseService.getDoctors();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctors: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Bác sĩ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDoctorForm(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return DoctorListTile(
                  doctor: doctor,
                  onEdit: () => _showDoctorForm(context, doctor),
                  onDelete: () => _deleteDoctor(doctor),
                );
              },
            ),
    );
  }

  Future<void> _showDoctorForm(BuildContext context, [Doctor? doctor]) async {
    final result = await showModalBottomSheet<Doctor>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DoctorForm(doctor: doctor),
    );

    if (result != null) {
      await _loadDoctors();
    }
  }

  Future<void> _deleteDoctor(Doctor doctor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bác sĩ ${doctor.name}?'),
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

    if (confirm == true) {
      try {
        await _supabaseService.deleteDoctor(doctor.id);
        await _loadDoctors();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting doctor: $e')),
        );
      }
    }
  }
}
