import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_management/models/prescription.dart';
import 'package:clinic_management/models/doctor.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/prescription/prescription_form_screen.dart';
import 'package:clinic_management/models/patient.dart';

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
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Chỉnh sửa'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _navigateToEdit(context),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.print),
                  title: Text('In toa thuốc'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _printPrescription(context),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<PrescriptionDetail>>(
        future: SupabaseService()
            .prescriptionService
            .getPrescriptionDetails(prescription.id),
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
    return Column(
      children: [
        FutureBuilder<Patient?>(
          future: prescription.patientId != null
              ? SupabaseService()
                  .patientService
                  .getPatientById(prescription.patientId!)
              : Future.value(null),
          builder: (context, patientSnapshot) {
            if (patientSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final patient = patientSnapshot.data;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin bệnh nhân:',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Họ tên: ${patient?.name ?? 'Không xác định'}'),
                    Text(
                        'Ngày sinh: ${patient?.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(patient!.dateOfBirth) : 'Không xác định'}'),
                    Text('Giới tính: ${patient?.gender ?? 'Không xác định'}'),
                    Text('Địa chỉ: ${patient?.address ?? 'Không xác định'}'),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<Doctor>(
          future: SupabaseService()
              .doctorService
              .getDoctorById(prescription.doctorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final doctor = snapshot.data;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bác sĩ kê toa: ${doctor?.name ?? 'Không xác định'}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
          },
        ),
      ],
    );
  }

  Widget _buildMedicinesList(List<PrescriptionDetail> details) {
    double totalCost = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách thuốc',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...details.map((detail) {
          final medicineCost =
              (detail.quantity * (detail.medicine?.price ?? 0)).toDouble();
          totalCost += medicineCost;
          return _buildMedicineCard(detail, medicineCost);
        }),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền thuốc:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                      .format(totalCost),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(PrescriptionDetail detail, double totalCost) {
    final medicine = detail.medicine;
    if (medicine == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Thuốc không tồn tại (ID: ${detail.medicineId})'),
        ),
      );
    }

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
            Text(
                'Thành tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalCost)}'),
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
