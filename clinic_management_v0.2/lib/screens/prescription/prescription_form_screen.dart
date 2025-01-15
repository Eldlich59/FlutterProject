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

  const PrescriptionFormScreen({
    super.key,
    this.prescription,
    this.isEditing = false,
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.isEditing && widget.prescription != null) {
      // Load existing prescription details
      _loadPrescriptionDetails();
    }
  }

  Future<void> _loadData() async {
    try {
      final medicines = await _supabaseService2.getMedicines();
      final patients = await _supabaseService3.getPatients();
      final doctors = await _supabaseService5.getDoctor();

      setState(() {
        _medicines = medicines;
        _patients = patients;
        _doctors = doctors;
        if (widget.prescription != null) {
          _selectedDoctor = doctors.firstWhere(
            (d) => d.id == widget.prescription!.doctorId,
            orElse: () => doctors.first,
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
      setState(() => _examinations = examinations);
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
        _selectedDoctor = _doctors.firstWhere(
          (d) => d.id == widget.prescription!.doctorId,
          orElse: () => _doctors.first,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải chi tiết toa thuốc: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Sửa toa thuốc' : 'Thêm toa thuốc mới'),
        actions: [
          if (widget.prescription !=
              null) // Only show delete button when editing
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
              color: Colors.red,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.prescription == null) ...[
                      DropdownButtonFormField<Patient>(
                        value: _selectedPatient,
                        decoration: const InputDecoration(
                          labelText: 'Chọn bệnh nhân',
                          border: OutlineInputBorder(),
                        ),
                        items: _patients.map((patient) {
                          return DropdownMenuItem(
                            value: patient,
                            child: Text('${patient.name} - ${patient.phone}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPatient = value;
                            _selectedExamination = null;
                          });
                          if (value != null) {
                            _loadExaminations(value.id!);
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Vui lòng chọn bệnh nhân';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedPatient != null)
                        DropdownButtonFormField<Examination>(
                          value: _selectedExamination,
                          decoration: const InputDecoration(
                            labelText: 'Chọn phiếu khám',
                            border: OutlineInputBorder(),
                          ),
                          items: _examinations.map((examination) {
                            return DropdownMenuItem(
                              value: examination,
                              child: Text('Phiếu khám ${examination.id}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedExamination = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Vui lòng chọn phiếu khám';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                    DropdownButtonFormField<Doctor>(
                      value: _selectedDoctor,
                      decoration: const InputDecoration(
                        labelText: 'Chọn bác sĩ',
                        border: OutlineInputBorder(),
                      ),
                      items: _doctors.map((doctor) {
                        return DropdownMenuItem(
                          value: doctor,
                          child: Text(doctor
                              .name), // Changed from '${doctor.id} - ${doctor.name}' to just doctor.name
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDoctor = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn bác sĩ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showAddMedicineDialog,
                      child: const Text('Thêm thuốc'),
                    ),
                    const SizedBox(height: 16),
                    ..._buildMedicineList(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePrescription,
                        child: const Text('Lưu toa thuốc'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildMedicineList() {
    return _details.map((detail) {
      final medicine = detail.medicine!;
      return Card(
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Số lượng: ${detail.quantity} ${medicine.unit}'),
                    Text('Cách dùng: ${detail.usage}'),
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
        );
      }
      Navigator.pop(context);
    } catch (e) {
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
}
