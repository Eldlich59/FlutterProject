import 'package:flutter/material.dart';
import 'package:clinic_management/models/prescription.dart';
import 'package:clinic_management/models/medicine.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/screens/medicine/add_medicine_dialog.dart';
import 'package:clinic_management/models/patient.dart';
import 'package:clinic_management/models/examination.dart';
import 'package:clinic_management/models/doctor.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final Prescription? prescription;
  final bool isEditing;
  final Examination? examination; // Add this line

  const PrescriptionFormScreen({
    super.key,
    this.prescription,
    this.isEditing = false,
    this.examination, // Add this line
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<PrescriptionDetail> _details = [];
  final _supabaseService1 = SupabaseService().prescriptionService;
  final _supabaseService2 = SupabaseService().medicineService;
  final _supabaseService3 = SupabaseService().patientService;
  final _supabaseService4 = SupabaseService().examinationService;
  final _supabaseService5 = SupabaseService().doctorService;

  List<Medicine> _medicines = [];
  List<Patient> _patients = [];
  List<Examination> _examinations = [];
  List<Doctor> _doctors = [];
  Patient? _selectedPatient;
  Examination? _selectedExamination;
  Doctor? _selectedDoctor;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start animation regardless of editing mode
    _animationController.forward();

    if (widget.prescription != null) {
      _selectedDate = widget.prescription!.prescriptionDate;
    }
    _loadData();
    if (widget.isEditing && widget.prescription != null) {
      // Load existing prescription details
      _loadPrescriptionDetails();
    }

    // Add this block to handle examination data
    if (widget.examination != null) {
      _loadExaminationData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final medicines = await _supabaseService2.getMedicines();
      final patients = await _supabaseService3.getPatients();
      final doctors = await _supabaseService5.getDoctor();

      if (widget.prescription?.patientId != null) {
        // Load patient info for existing prescription
        final patient = await _supabaseService3
            .getPatientById(widget.prescription!.patientId!);
        setState(() => _selectedPatient = patient);
        // Load examinations for this patient if patient exists
        if (patient != null && patient.id != null) {
          await _loadExaminations(patient.id!);
        }
      }

      setState(() {
        _medicines = medicines;
        _patients = patients;
        _doctors = doctors;
        if (widget.prescription != null && doctors.isNotEmpty) {
          _selectedDoctor = doctors.firstWhere(
            (d) => d.id == widget.prescription!.doctorId,
            orElse: () => doctors[0],
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExaminations(String patientId) async {
    try {
      final examinations =
          await _supabaseService4.getExaminations(patientId: patientId);
      if (examinations.isNotEmpty) {
        examinations
            .sort((a, b) => b.examinationDate.compareTo(a.examinationDate));
        setState(() {
          _examinations = examinations;
          _selectedExamination = examinations.first;
          // Automatically select the doctor from the examination
          if (_selectedExamination != null && _doctors.isNotEmpty) {
            _selectedDoctor = _doctors.firstWhere(
              (d) => d.id == _selectedExamination!.doctorId,
              orElse: () => _doctors.firstWhere((d) => d.isActive,
                  orElse: () => _doctors[0]),
            );
          }
        });
      } else {
        setState(() {
          _examinations = [];
          _selectedExamination = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách khám: $e')),
      );
    }
  }

  Future<void> _loadPrescriptionDetails() async {
    setState(() => _isLoading = true);
    try {
      final details = await _supabaseService1.getPrescriptionDetails(
        widget.prescription!.id,
      );
      setState(() {
        _details.addAll(details);
        if (_doctors.isNotEmpty) {
          // Find matching doctor if exists
          _selectedDoctor = _doctors.firstWhere(
            (d) => d.id == widget.prescription!.doctorId,
            orElse: () => _doctors[0], // Default to first doctor if not found
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildPatientInfo() {
    if (_selectedPatient == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin bệnh nhân',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.person,
                        size: 35, color: Colors.orange.shade800),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPatient!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SĐT: ${_selectedPatient!.phone}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        if (!widget.isEditing && _selectedExamination != null)
                          Text(
                            'Phiếu khám số: ${_selectedExamination!.id.substring(0, 6)}...',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange.shade400,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Sửa toa thuốc' : 'Thêm toa thuốc mới',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.prescription != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
              color: Colors.red,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ))
          : FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(_animation),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.orange.shade50, Colors.white],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.prescription == null) ...[
                            _buildSectionHeader('Chọn bệnh nhân'),
                            const SizedBox(height: 8),
                            _buildDropdownField(
                              value: _selectedPatient?.id,
                              items: _patients.map((patient) {
                                return DropdownMenuItem(
                                  value: patient.id,
                                  child: Text(
                                      '${patient.name} - ${patient.phone}'),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                if (value != null) {
                                  final selectedPatient = _patients.firstWhere(
                                    (patient) => patient.id == value,
                                  );
                                  setState(() {
                                    _selectedPatient = selectedPatient;
                                    _selectedExamination =
                                        null; // Reset examination before loading new ones
                                    _examinations =
                                        []; // Clear existing examinations
                                  });
                                  await _loadExaminations(
                                      value); // Load and auto-select most recent examination
                                }
                              },
                              labelText: 'Chọn bệnh nhân',
                            ),
                            const SizedBox(height: 16),
                            _buildPatientInfo(),
                            if (_selectedPatient != null) ...[
                              const SizedBox(height: 16),
                              _buildSectionHeader('Thông tin khám'),
                              const SizedBox(height: 8),
                              _buildDropdownField(
                                value: _selectedExamination,
                                items: _examinations.map((examination) {
                                  return DropdownMenuItem(
                                    value: examination,
                                    child: Text(
                                        'Phiếu khám ${examination.id.substring(0, 6)}...'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedExamination = value;
                                    // Automatically select the doctor when examination changes
                                    if (value != null && _doctors.isNotEmpty) {
                                      _selectedDoctor = _doctors.firstWhere(
                                        (d) => d.id == value.doctorId,
                                        orElse: () => _doctors.firstWhere(
                                            (d) => d.isActive,
                                            orElse: () => _doctors[0]),
                                      );
                                    }
                                  });
                                },
                                labelText: 'Chọn phiếu khám',
                              ),
                            ],
                          ] else
                            _buildPatientInfo(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Thông tin kê đơn'),
                          const SizedBox(height: 8),
                          _buildDropdownField(
                            value: _selectedDoctor,
                            items: _doctors.map((doctor) {
                              return DropdownMenuItem(
                                value: doctor,
                                child: Text(
                                  doctor.name +
                                      (doctor.isActive
                                          ? ''
                                          : ' (Ngừng hoạt động)'),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedDoctor = value);
                            },
                            labelText: 'Chọn bác sĩ',
                          ),
                          const SizedBox(height: 16),
                          _buildDatePicker(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Danh sách thuốc'),
                          const SizedBox(height: 16),
                          _buildAddMedicineButton(),
                          const SizedBox(height: 16),
                          ..._buildMedicineList(),
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.orange.shade800,
      ),
    );
  }

  Widget _buildDropdownField({
    required dynamic value,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
    required String labelText,
  }) {
    if (labelText == 'Chọn bác sĩ') {
      items = items.map((item) {
        final doctor = item.value as Doctor;
        return DropdownMenuItem(
          value: doctor,
          enabled: doctor.isActive ||
              (value != null && doctor.id == (value as Doctor).id),
          child: Container(
            constraints: const BoxConstraints(minWidth: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    doctor.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: doctor.isActive ? null : Colors.grey,
                    ),
                  ),
                ),
                if (!doctor.isActive)
                  Opacity(
                    opacity: doctor.id == (value as Doctor?)?.id ? 1.0 : 0.5,
                    child: const Text(
                      ' (Ngừng hoạt động)',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          DropdownButtonFormField(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: labelText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null) {
                return 'Vui lòng chọn $labelText';
              }
              if (labelText == 'Chọn bác sĩ') {
                final doctor = value as Doctor;
                if (!doctor.isActive) {
                  return 'Vui lòng chọn bác sĩ đang hoạt động';
                }
              }
              return null;
            },
          ),
          if (labelText == 'Chọn bác sĩ' &&
              value != null &&
              !(value as Doctor).isActive)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bác sĩ này hiện không còn hoạt động',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Ngày kê toa',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              Icon(Icons.calendar_today, color: Colors.orange.shade800),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMedicineButton() {
    return ElevatedButton.icon(
      onPressed: _showAddMedicineDialog,
      icon: const Icon(Icons.add),
      label: const Text('Thêm thuốc'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  List<Widget> _buildMedicineList() {
    return _details.map((detail) {
      final medicine = detail.medicine!;
      return Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.medication, color: Colors.orange.shade800),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số lượng: ${detail.quantity} ${medicine.unit}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text(
                        'Cách dùng: ${detail.usage}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeDetail(detail),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showAddMedicineDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMedicineDialog(
        medicines: _medicines,
        onAdd: _addDetail,
      ),
    );
  }

  void _addDetail(PrescriptionDetail detail) {
    setState(() => _details.add(detail));
  }

  void _removeDetail(PrescriptionDetail detail) {
    setState(() => _details.remove(detail));
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate() || _details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Vui lòng điền đầy đủ thông tin và thêm ít nhất một thuốc'),
        ),
      );
      return;
    }

    try {
      if (widget.isEditing) {
        await _supabaseService1.updatePrescription(
          widget.prescription!.id,
          _selectedDoctor!.id,
          _details,
          prescriptionDate: _selectedDate, // Add this parameter
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật toa thuốc thành công')),
        );
      } else {
        await _supabaseService1.createPrescription(
          _selectedDoctor!.id,
          _details,
          patientId: _selectedPatient!.id!,
          examId: _selectedExamination!.id,
          prescriptionDate: _selectedDate, // Ensure this parameter is passed
        );
      }
      if (!mounted) return; // Add mounted check here
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return; // Add mounted check here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu toa thuốc: $e')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa toa thuốc này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.pop(dialogContext); // Close dialog
                  await _supabaseService1
                      .deletePrescription(widget.prescription!.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã xóa toa thuốc thành công')),
                    );
                    Navigator.pop(context); // Return to prescription list
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa toa thuốc: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadExaminationData() async {
    try {
      final patient =
          await _supabaseService3.getPatientById(widget.examination!.patientId);
      setState(() => _selectedPatient = patient);

      final examinations = await _supabaseService4.getExaminations(
          patientId: widget.examination!.patientId);

      setState(() {
        _examinations = examinations;
        _selectedExamination = examinations.firstWhere(
          (e) => e.id == widget.examination!.id,
          orElse: () => widget.examination!,
        );
        // Automatically select the doctor from the examination
        if (_selectedExamination != null && _doctors.isNotEmpty) {
          _selectedDoctor = _doctors.firstWhere(
            (d) => d.id == _selectedExamination!.doctorId,
            orElse: () => _doctors.firstWhere((d) => d.isActive,
                orElse: () => _doctors[0]),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin bệnh nhân: $e')),
        );
      }
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _savePrescription,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Lưu toa thuốc'),
      ),
    );
  }
}
