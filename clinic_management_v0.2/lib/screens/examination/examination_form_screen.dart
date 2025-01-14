import 'package:flutter/material.dart';
import 'package:clinic_management/models/examination.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/models/patient.dart';
import 'package:intl/intl.dart';

class ExaminationFormScreen extends StatefulWidget {
  final Examination? examination;
  final String? patientId;
  const ExaminationFormScreen({super.key, this.examination, this.patientId});

  @override
  State<ExaminationFormScreen> createState() => _ExaminationFormScreenState();
}

class _ExaminationFormScreenState extends State<ExaminationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService1 = SupabaseService().patientService;
  final _supabaseService2 = SupabaseService().examinationService;

  late TextEditingController _symptomsController;
  late TextEditingController _diagnosisController;
  late TextEditingController _feeController;
  // Initialize _selectedDate directly instead of using late
  DateTime _selectedDate = DateTime.now();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Patient? _selectedPatient;
  List<Patient> _patients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Update _selectedDate if examination exists
    if (widget.examination != null) {
      _selectedDate = widget.examination!.examinationDate;
    }
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
      final patients = await _supabaseService1.getPatients();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // Store current time components
      final currentTime = TimeOfDay.fromDateTime(_selectedDate);

      // Show time picker with current time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: currentTime,
      );

      if (mounted) {
        setState(() {
          if (pickedTime != null) {
            // Create new DateTime combining picked date with picked time
            _selectedDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          } else {
            // If time wasn't picked, keep current time
            _selectedDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              currentTime.hour,
              currentTime.minute,
            );
          }
        });
      }
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
            ListTile(
              title: const Text('Ngày khám'),
              subtitle: Text(_dateFormat.format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
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
        examinationDate: _selectedDate,
        symptoms: _symptomsController.text,
        diagnosis: _diagnosisController.text,
        examinationFee: double.parse(_feeController.text),
      );

      if (widget.examination == null) {
        await _supabaseService2.addExamination(examination);
      } else {
        await _supabaseService2.updateExamination(examination);
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
