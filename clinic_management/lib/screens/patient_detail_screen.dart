import 'package:flutter/material.dart';
import '../models/patient.dart';

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.tenBN),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Mã BN:', patient.maBN),
            _buildInfoRow('Họ tên:', patient.tenBN),
            _buildInfoRow('Ngày sinh:', _formatDate(patient.ngaySinh)),
            _buildInfoRow('Giới tính:', patient.gioiTinh),
            _buildInfoRow('SĐT:', patient.sdt ?? 'N/A'),
            _buildInfoRow('Địa chỉ:', patient.diaChi ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
