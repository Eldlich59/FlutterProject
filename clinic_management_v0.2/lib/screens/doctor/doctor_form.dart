import 'package:flutter/material.dart';
import 'package:clinic_management/models/doctor.dart';
import 'package:clinic_management/services/supabase_service.dart';

class DoctorForm extends StatefulWidget {
  final Doctor? doctor;

  const DoctorForm({super.key, this.doctor});

  @override
  State<DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<DoctorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late DateTime _dateOfBirth;
  DateTime? _startDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final doctor = widget.doctor;
    _nameController = TextEditingController(text: doctor?.name ?? '');
    _specialtyController = TextEditingController(text: doctor?.specialty ?? '');
    _phoneController = TextEditingController(text: doctor?.phone ?? '');
    _emailController = TextEditingController(text: doctor?.email ?? '');
    _dateOfBirth = doctor?.dateOfBirth ?? DateTime.now();
    _startDate = doctor?.startDate;
    _isActive = doctor?.isActive ?? true;
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate ? _dateOfBirth : (_startDate ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _dateOfBirth = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên bác sĩ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên bác sĩ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: 'Chuyên khoa',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập chuyên khoa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Ngày sinh: ${_formatDate(_dateOfBirth)}'),
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text('Ngày bắt đầu: ${_formatDate(_startDate)}'),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Trạng thái hoạt động'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(widget.doctor == null ? 'Thêm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final doctor = Doctor(
        id: widget.doctor?.id ?? '',
        name: _nameController.text,
        specialty: _specialtyController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        dateOfBirth: _dateOfBirth,
        startDate: _startDate,
        isActive: _isActive,
      );

      try {
        final supabaseService = SupabaseService().doctorService;
        if (widget.doctor == null) {
          await supabaseService.addDoctor(doctor);
        } else {
          await supabaseService.updateDoctor(doctor);
        }
        Navigator.pop(context, doctor);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving doctor: $e')),
        );
      }
    }
  }
}
