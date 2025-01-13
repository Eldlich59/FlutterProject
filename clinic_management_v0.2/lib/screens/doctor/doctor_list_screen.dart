import 'package:flutter/material.dart';
import 'package:clinic_management/models/doctor.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/doctor/doctor_form.dart';

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
      doctors = await _supabaseService.getDoctor();
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
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(doctor.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chuyên khoa: ${doctor.specialty}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            )),
                        Text(
                          'Ngày sinh: ${_formatDate(doctor.dateOfBirth)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Ngày bắt đầu: ${_formatDate(doctor.startDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: const ListTile(
                            leading: Icon(Icons.info),
                            title: Text('Chi tiết'),
                            dense: true,
                          ),
                          onTap: () => Future.delayed(
                            const Duration(seconds: 0),
                            () => _showDoctorDetails(doctor),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: const ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Sửa'),
                            dense: true,
                          ),
                          onTap: () => Future.delayed(
                            const Duration(seconds: 0),
                            () => _showDoctorForm(context, doctor),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: const ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Xóa',
                                style: TextStyle(color: Colors.red)),
                            dense: true,
                          ),
                          onTap: () => Future.delayed(
                            const Duration(seconds: 0),
                            () => _deleteDoctor(doctor),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDoctorDetails(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doctor.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.work),
              title: Text('Chuyên khoa: ${doctor.specialty}'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text('Điện thoại: ${doctor.phone}'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text('Email: ${doctor.email}'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Ngày sinh: ${_formatDate(doctor.dateOfBirth)}'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text('Ngày bắt đầu: ${_formatDate(doctor.startDate)}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pop(context);
              _showDoctorForm(context, doctor);
            },
            label: const Text('Cập nhật'),
          ),
        ],
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
