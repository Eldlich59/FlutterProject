import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/prescription.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/prescription/prescription_form_screen.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết toa thuốc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printPrescription(context),
          ),
        ],
      ),
      body: FutureBuilder<List<PrescriptionDetail>>(
        future: SupabaseService().getPrescriptionDetails(prescription.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final details = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(),
                const SizedBox(height: 24),
                _buildMedicinesList(details),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bác sĩ kê toa: ${prescription.doctorName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày kê toa: ${DateFormat('dd/MM/yyyy HH:mm').format(prescription.prescriptionDate)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesList(List<PrescriptionDetail> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách thuốc',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...details.map((detail) => _buildMedicineCard(detail)).toList(),
      ],
    );
  }

  Widget _buildMedicineCard(PrescriptionDetail detail) {
    final medicine = detail.medicine!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medicine.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Số lượng: ${detail.quantity} ${medicine.unit}'),
            Text(
                'Đơn giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(medicine.price)}'),
            const SizedBox(height: 8),
            Text(
              'Cách dùng:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(detail.usage),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PrescriptionFormScreen(prescription: prescription),
      ),
    );
  }

  void _printPrescription(BuildContext context) {
    // Implement printing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Tính năng in toa thuốc đang được phát triển')),
    );
  }
}