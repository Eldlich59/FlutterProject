import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../models/patient.dart';

class AddPatientScreen extends StatefulWidget {
  final Patient? patient;

  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _maBNController;
  late TextEditingController _tenBNController;
  late TextEditingController _sdtController;
  late TextEditingController _diaChiController;
  DateTime? _selectedDate;
  String _selectedGender = 'Nam';

  @override
  void initState() {
    super.initState();
    _maBNController = TextEditingController(text: widget.patient?.maBN);
    _tenBNController = TextEditingController(text: widget.patient?.tenBN);
    _sdtController = TextEditingController(text: widget.patient?.sdt);
    _diaChiController = TextEditingController(text: widget.patient?.diaChi);
    _selectedDate = widget.patient?.ngaySinh;
    _selectedGender = widget.patient?.gioiTinh ?? 'Nam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.patient == null ? 'Thêm bệnh nhân' : 'Cập nhật bệnh nhân'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _maBNController,
              decoration: const InputDecoration(labelText: 'Mã bệnh nhân'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập mã bệnh nhân' : null,
            ),
            TextFormField(
              controller: _tenBNController,
              decoration: const InputDecoration(labelText: 'Tên bệnh nhân'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập tên bệnh nhân' : null,
            ),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: ['Nam', 'Nữ']
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
            TextFormField(
              controller: _sdtController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: _diaChiController,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
              maxLines: 2,
            ),
            ElevatedButton(
              onPressed: _savePatient,
              child: Text(widget.patient == null ? 'Thêm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    final patient = Patient(
      maBN: _maBNController.text,
      tenBN: _tenBNController.text,
      ngaySinh: _selectedDate ?? DateTime.now(),
      gioiTinh: _selectedGender,
      sdt: _sdtController.text,
      diaChi: _diaChiController.text,
    );

    final provider = Provider.of<PatientProvider>(context, listen: false);

    try {
      if (widget.patient == null) {
        await provider.createPatient(patient);
      } else {
        await provider.updatePatient(patient);
      }
      if (!mounted) return; // Add mounted check
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _maBNController.dispose();
    _tenBNController.dispose();
    _sdtController.dispose();
    _diaChiController.dispose();
    super.dispose();
  }
}
