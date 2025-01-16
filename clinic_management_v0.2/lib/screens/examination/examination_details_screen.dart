import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/examination.dart';
import '../prescription/prescription_form_screen.dart';
import 'examination_form_screen.dart';

class ExaminationDetailsScreen extends StatelessWidget {
  final Examination examination;
  final Function() onExaminationUpdated;

  const ExaminationDetailsScreen({
    super.key,
    required this.examination,
    required this.onExaminationUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phiếu khám'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.medical_services),
            onPressed: () => _navigateToPrescription(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Bệnh nhân:', examination.patientName ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Ngày khám:',
                    dateFormat.format(examination.examinationDate)),
                const SizedBox(height: 12),
                _buildInfoRow('Triệu chứng:', examination.symptoms),
                const SizedBox(height: 12),
                _buildInfoRow('Chẩn đoán:', examination.diagnosis),
                const SizedBox(height: 12),
                _buildInfoRow('Phí khám:',
                    currencyFormat.format(examination.examinationFee)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExaminationFormScreen(examination: examination),
      ),
    );

    if (result == true) {
      onExaminationUpdated();
    }
  }

  void _navigateToPrescription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionFormScreen(examination: examination),
      ),
    );
  }
}
