import 'package:flutter/material.dart';
import 'package:clinic_management/models/medicine.dart';
import 'package:clinic_management/models/prescription.dart';

class AddMedicineDialog extends StatefulWidget {
  final List<Medicine> medicines;
  final Function(PrescriptionDetail) onAdd;

  const AddMedicineDialog({
    super.key,
    required this.medicines,
    required this.onAdd,
  });

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  Medicine? _selectedMedicine;
  final _quantityController = TextEditingController();
  final _usageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm thuốc'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Medicine>(
              value: _selectedMedicine,
              decoration: const InputDecoration(
                labelText: 'Chọn thuốc',
                border: OutlineInputBorder(),
              ),
              items: widget.medicines.map((medicine) {
                return DropdownMenuItem(
                  value: medicine,
                  child: Text(medicine.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedMedicine = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn thuốc';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Số lượng',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số lượng';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Số lượng không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usageController,
              decoration: const InputDecoration(
                labelText: 'Cách dùng',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập cách dùng';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _addMedicine,
          child: const Text('Thêm'),
        ),
      ],
    );
  }

  void _addMedicine() {
    if (_formKey.currentState!.validate()) {
      final detail = PrescriptionDetail(
        prescriptionId: '', // Will be set when saving the prescription
        medicineId: _selectedMedicine!.id.toString(),
        quantity: int.parse(_quantityController.text),
        usage: _usageController.text,
        medicine: _selectedMedicine,
      );
      widget.onAdd(detail);
      Navigator.pop(context);
    }
  }
}
