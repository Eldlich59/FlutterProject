import 'package:flutter/material.dart';
import 'package:clinic_management/models/doctor.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/models/specialty.dart';

class DoctorForm extends StatefulWidget {
  final Doctor? doctor;

  const DoctorForm({super.key, this.doctor});

  @override
  State<DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<DoctorForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late DateTime _dateOfBirth;
  DateTime? _startDate;
  bool _isActive = true;
  List<Specialty> _specialties = [];
  String? _selectedSpecialtyId;
  bool _loadingSpecialties = true;
  bool _showInactiveSpecialtyWarning = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Add color constants
  final Color primaryPurple = const Color(0xFF6B4EAB);
  final Color lightPurple = const Color(0xFFE5E0F3);
  final Color darkPurple = const Color(0xFF4A3579);

  @override
  void initState() {
    super.initState();
    final doctor = widget.doctor;
    _nameController = TextEditingController(text: doctor?.name ?? '');
    _phoneController = TextEditingController(text: doctor?.phone ?? '');
    _emailController = TextEditingController(text: doctor?.email ?? '');
    _dateOfBirth = doctor?.dateOfBirth ?? DateTime.now();
    _startDate = doctor?.startDate;
    _isActive = doctor?.isActive ?? true;
    _loadSpecialties();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    try {
      final specialties =
          await SupabaseService().specialtyService.getSpecialties();
      setState(() {
        _specialties = specialties;
        if (widget.doctor != null) {
          // Find the specialty for this doctor
          final currentSpecialty = _specialties.firstWhere(
            (s) => s.name == widget.doctor!.specialty,
            orElse: () => _specialties.first,
          );

          _selectedSpecialtyId = currentSpecialty.id;

          // Show warning if current specialty is inactive
          if (!currentSpecialty.isActive) {
            _showInactiveSpecialtyWarning = true;
          }
        }
        _loadingSpecialties = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading specialties: $e')),
      );
    }
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _animationController,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lightPurple, Colors.white],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, lightPurple.withOpacity(0.1)],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.doctor == null
                            ? 'Thêm Bác Sĩ Mới'
                            : 'Cập Nhật Thông Tin',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: darkPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên bác sĩ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.person, color: primaryPurple),
                          filled: true,
                          fillColor: Colors.white,
                          labelStyle: TextStyle(color: darkPurple),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: primaryPurple, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên bác sĩ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_showInactiveSpecialtyWarning)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chuyên khoa hiện tại đã ngừng hoạt động. Vui lòng chọn chuyên khoa mới.',
                                  style:
                                      TextStyle(color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _loadingSpecialties
                          ? const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedSpecialtyId,
                              decoration: InputDecoration(
                                labelText: 'Chuyên khoa',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(Icons.local_hospital,
                                    color: primaryPurple),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: darkPurple),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: primaryPurple, width: 2),
                                ),
                              ),
                              items: [
                                ..._specialties
                                    .map((specialty) => DropdownMenuItem(
                                          value: specialty.id,
                                          enabled: specialty.isActive ||
                                              specialty.id ==
                                                  _selectedSpecialtyId,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                minWidth: 100, maxWidth: 300),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Opacity(
                                                    opacity: specialty.isActive
                                                        ? 1.0
                                                        : 0.5,
                                                    child: Text(
                                                      specialty.name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                if (!specialty.isActive)
                                                  Opacity(
                                                    opacity: specialty.id ==
                                                            _selectedSpecialtyId
                                                        ? 1.0
                                                        : 0.5,
                                                    child: const Text(
                                                      ' (Ngừng hoạt động)',
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSpecialtyId = value;
                                  // Clear warning if new specialty is active
                                  if (value != null) {
                                    final newSpecialty = _specialties
                                        .firstWhere((s) => s.id == value);
                                    _showInactiveSpecialtyWarning =
                                        !newSpecialty.isActive;
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng chọn chuyên khoa';
                                }
                                // Add validation for active specialty
                                final selectedSpecialty = _specialties
                                    .firstWhere((s) => s.id == value);
                                if (!selectedSpecialty.isActive) {
                                  return 'Vui lòng chọn chuyên khoa đang hoạt động';
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Số điện thoại',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon:
                                      Icon(Icons.phone, color: primaryPurple),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(color: darkPurple),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: primaryPurple, width: 2),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon:
                                      Icon(Icons.email, color: primaryPurple),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(color: darkPurple),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: primaryPurple, width: 2),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.white,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.calendar_today,
                                  color: primaryPurple),
                              title: const Text('Ngày sinh'),
                              subtitle: Text(_formatDate(_dateOfBirth)),
                              onTap: () => _selectDate(context, true),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                            Divider(height: 1, color: lightPurple),
                            ListTile(
                              leading:
                                  Icon(Icons.date_range, color: primaryPurple),
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
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SwitchListTile(
                          secondary: Icon(
                            _isActive ? Icons.check_circle : Icons.cancel,
                            color: _isActive ? Colors.green : Colors.red,
                          ),
                          title: const Text('Trạng thái hoạt động'),
                          subtitle: Text(
                              _isActive ? 'Đang hoạt động' : 'Ngừng hoạt động'),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          activeColor: primaryPurple,
                          inactiveTrackColor: lightPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SafeArea(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: primaryPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            widget.doctor == null ? 'Thêm Bác Sĩ' : 'Cập Nhật',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
      if (_selectedSpecialtyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn chuyên khoa mới')),
        );
        return;
      }

      final selectedSpecialty = _specialties.firstWhere(
        (s) => s.id == _selectedSpecialtyId,
      );

      final doctor = Doctor(
        id: widget.doctor?.id ?? '',
        name: _nameController.text,
        specialty: selectedSpecialty.name, // Use selected specialty name
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
