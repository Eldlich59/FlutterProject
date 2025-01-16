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
      child: SingleChildScrollView(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.doctor == null
                              ? 'Thêm Bác Sĩ Mới'
                              : 'Cập Nhật Thông Tin',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the layout
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên bác sĩ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      filled: true,
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
                      prefixIcon: Icon(Icons.local_hospital),
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập chuyên khoa';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            filled: true,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                            filled: true,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Ngày sinh'),
                          subtitle: Text(_formatDate(_dateOfBirth)),
                          onTap: () => _selectDate(context, true),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.date_range),
                          title: const Text('Ngày bắt đầu'),
                          subtitle: Text(_formatDate(_startDate)),
                          onTap: () => _selectDate(context, false),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      secondary: Icon(
                        _isActive ? Icons.check_circle : Icons.cancel,
                        color: _isActive ? Colors.green : Colors.red,
                      ),
                      title: const Text('Trạng thái hoạt động'),
                      subtitle: Text(
                          _isActive ? 'Đang hoạt động' : 'Ngừng hoạt động'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SafeArea(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.doctor == null ? 'Thêm Bác Sĩ' : 'Cập Nhật',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
