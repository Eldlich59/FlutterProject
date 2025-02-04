import 'package:flutter/material.dart';
import 'package:clinic_management/models/inventory/medicine.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.medical_services, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            'Thêm thuốc',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Medicine>(
                value: _selectedMedicine,
                decoration: InputDecoration(
                  labelText: 'Chọn thuốc',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.medication),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: widget.medicines.map((medicine) {
                  return DropdownMenuItem(
                    value: medicine,
                    child: Text(
                      medicine.name,
                      style: const TextStyle(fontSize: 15),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMedicine = value);
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn thuốc' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Số lượng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Colors.grey[50],
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
                decoration: InputDecoration(
                  labelText: 'Cách dùng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 2,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập cách dùng' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Hủy',
            style: TextStyle(fontSize: 15),
          ),
        ),
        ElevatedButton(
          onPressed: _addMedicine,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text(
                'Thêm',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  void _addMedicine() {
    if (_formKey.currentState!.validate()) {
      final detail = PrescriptionDetail(
        id: '',
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
