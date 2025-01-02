import 'package:flutter/material.dart';
import 'package:clinic_management/models/examination.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/models/patient.dart';

class ExaminationFormScreen extends StatefulWidget {
  final Examination? examination;
  final String? patientId;
  const ExaminationFormScreen({super.key, this.examination, this.patientId});

  @override
  State<ExaminationFormScreen> createState() => _ExaminationFormScreenState();
}

class _ExaminationFormScreenState extends State<ExaminationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _symptomsController;
  late TextEditingController _diagnosisController;
  late TextEditingController _feeController;

  Patient? _selectedPatient;
  List<Patient> _patients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _symptomsController =
        TextEditingController(text: widget.examination?.symptoms);
    _diagnosisController =
        TextEditingController(text: widget.examination?.diagnosis);
    _feeController = TextEditingController(
      text: widget.examination?.examinationFee.toString() ?? '100000',
    );
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _supabaseService.getPatients();
      setState(() => _patients = patients);
      if (widget.examination != null) {
        _selectedPatient = _patients.firstWhere(
          (p) => p.id == widget.examination!.patientId,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.examination == null ? 'Thêm phiếu khám' : 'Sửa phiếu khám'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Patient>(
              value: _selectedPatient,
              decoration: const InputDecoration(
                labelText: 'Bệnh nhân',
                border: OutlineInputBorder(),
              ),
              items: _patients.map((patient) {
                return DropdownMenuItem(
                  value: patient,
                  child: Text(patient.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPatient = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn bệnh nhân';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _symptomsController,
              decoration: const InputDecoration(
                labelText: 'Triệu chứng',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập triệu chứng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Chẩn đoán',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập chẩn đoán';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feeController,
              decoration: const InputDecoration(
                labelText: 'Tiền khám',
                border: OutlineInputBorder(),
                suffixText: 'VNĐ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiền khám';
                }
                if (double.tryParse(value) == null) {
                  return 'Tiền khám không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.examination == null ? 'Thêm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedPatient == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final examination = Examination(
        id: widget.examination?.id ?? '',
        patientId: _selectedPatient!.id ?? '',
        patientName: _selectedPatient!.name,
        examinationDate: DateTime.now(),
        symptoms: _symptomsController.text,
        diagnosis: _diagnosisController.text,
        examinationFee: double.parse(_feeController.text),
      );

      if (widget.examination == null) {
        await _supabaseService.addExamination(examination);
      } else {
        await _supabaseService.updateExamination(examination);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _feeController.dispose();
    super.dispose();
  }
}
