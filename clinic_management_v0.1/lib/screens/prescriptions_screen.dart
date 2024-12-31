import 'package:flutter/material.dart';
import '../models/prescription.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final List<Prescription> _prescriptions =
      []; // Replace with actual data source

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPrescriptionDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _prescriptions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('Prescription #${prescription.id}'),
              subtitle:
                  Text('Date: ${prescription.prescriptionDate.toString()}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () => _printPrescription(prescription),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showEditPrescriptionDialog(context, prescription),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddPrescriptionDialog(BuildContext context) {
    // Implement add prescription dialog
  }

  void _showEditPrescriptionDialog(
      BuildContext context, Prescription prescription) {
    // Implement edit prescription dialog
  }

  void _printPrescription(Prescription prescription) {
    // Implement print functionality
  }
}
