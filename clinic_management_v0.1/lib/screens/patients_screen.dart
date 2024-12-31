import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../models/patient.dart';
import 'add_patient_screen.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bệnh nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddPatientScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PatientProvider>(
        builder: (context, patientProvider, child) {
          if (patientProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (patientProvider.error != null) {
            return Center(child: Text('Error: ${patientProvider.error}'));
          }

          if (patientProvider.patients.isEmpty) {
            return const Center(child: Text('Không có bệnh nhân'));
          }

          return ListView.builder(
            itemCount: patientProvider.patients.length,
            itemBuilder: (context, index) {
              final patient = patientProvider.patients[index];
              return _buildPatientCard(context, patient);
            },
          );
        },
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(patient.tenBN),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã BN: ${patient.maBN}'),
            Text('SĐT: ${patient.sdt ?? 'N/A'}'),
            Text('Địa chỉ: ${patient.diaChi ?? 'N/A'}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPatientScreen(patient: patient),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmationDialog(context, patient);
              },
            ),
          ],
        ),
        onTap: () {
          // Navigate to patient details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailScreen(patient: patient),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    Patient patient,
  ) async {
    final provider = Provider.of<PatientProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bệnh nhân ${patient.tenBN}?'),
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

    if (confirmed ?? false) {
      if (context.mounted) {
        await provider.deletePatient(patient.maBN);
      }
    }
  }
}
