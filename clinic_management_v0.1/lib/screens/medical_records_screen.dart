import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medical_record_provider.dart';
import '../models/medical_record.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<MedicalRecordProvider>(context, listen: false).loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ bệnh án'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecordDialog(context),
          ),
        ],
      ),
      body: Consumer<MedicalRecordProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          if (provider.records.isEmpty) {
            return const Center(child: Text('Chưa có hồ sơ bệnh án nào'));
          }

          return ListView.builder(
            itemCount: provider.records.length,
            itemBuilder: (context, index) {
              final record = provider.records[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Mã phiếu khám: ${record.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ngày khám: ${_formatDate(record.date)}'),
                      Text('Chẩn đoán: ${record.diagnosis}'),
                      Text('Tiền khám: ${_formatCurrency(record.fee)}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _showRecordDetails(context, record),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }

  void _showRecordDetails(BuildContext context, MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết phiếu khám ${record.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ngày khám: ${_formatDate(record.date)}'),
              const SizedBox(height: 8),
              Text('Triệu chứng: ${record.symptoms}'),
              const SizedBox(height: 8),
              Text('Chẩn đoán: ${record.diagnosis}'),
              const SizedBox(height: 8),
              Text('Tiền khám: ${_formatCurrency(record.fee)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    // Implement add record dialog
  }
}
