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
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.doctor != null) {
      _nameController.text = widget.doctor!.name;
      _specialtyController.text = widget.doctor!.specialty;
      _phoneController.text = widget.doctor!.phone ?? '';
      _emailController.text = widget.doctor!.email ?? '';
      _isActive = widget.doctor!.isActive;
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final doctor = Doctor(
        id: widget.doctor?.id ?? '',
        name: _nameController.text,
        specialty: _specialtyController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        startDate: widget.doctor?.startDate ?? DateTime.now(),
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
