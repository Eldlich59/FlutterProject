import 'package:flutter/material.dart';
import 'package:clinic_management/models/examination.dart';
import 'package:clinic_management/services/supabase_service.dart';
import 'package:clinic_management/models/patient.dart';
import 'package:intl/intl.dart';
import 'package:flutter/animation.dart';

class ExaminationFormScreen extends StatefulWidget {
  final Examination? examination;
  final String? patientId;
  const ExaminationFormScreen({super.key, this.examination, this.patientId});

  @override
  State<ExaminationFormScreen> createState() => _ExaminationFormScreenState();
}

class _ExaminationFormScreenState extends State<ExaminationFormScreen>
    with SingleTickerProviderStateMixin {
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

  // Add custom colors
  final Color primaryBlue = const Color(0xFF1976D2);
  final Color lightBlue = const Color(0xFFBBDEFB);
  final Color darkBlue = const Color(0xFF0D47A1);

  // Initialize animations with default values
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final Animation<double> _fadeInAnimation = CurvedAnimation(
    parent: _animationController,
    curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
  );

  late final Animation<Offset> _slideAnimation1 = Tween<Offset>(
    begin: const Offset(0.5, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
  ));

  late final Animation<Offset> _slideAnimation2 = Tween<Offset>(
    begin: const Offset(0.5, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
  ));

  late final Animation<Offset> _slideAnimation3 = Tween<Offset>(
    begin: const Offset(0.5, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
  ));

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

    _animationController.forward();
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
          widget.examination == null ? 'Thêm phiếu khám' : 'Sửa phiếu khám',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightBlue.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation1,
                  child: _buildExaminationInfoCard(),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation2,
                  child: _buildExaminationDetailsCard(),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation3,
                  child: _buildSubmitButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExaminationInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: primaryBlue.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              lightBlue.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Thông tin khám bệnh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFormFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildExaminationDetailsCard() {
    return Card(
      elevation: 4,
      shadowColor: primaryBlue.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              lightBlue.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Chi tiết khám bệnh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailsFormFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: primaryBlue.withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.examination == null ? Icons.add : Icons.update),
                  const SizedBox(width: 8),
                  Text(
                    widget.examination == null ? 'Thêm phiếu khám' : 'Cập nhật',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
        ),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<Patient>(
            value: _selectedPatient,
            decoration: InputDecoration(
              labelText: 'Bệnh nhân',
              prefixIcon: Icon(Icons.person, color: primaryBlue),
              filled: true,
              fillColor: Colors.white,
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
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: primaryBlue.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: primaryBlue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày khám',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _dateFormat.format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _symptomsController,
          decoration: InputDecoration(
            labelText: 'Triệu chứng',
            prefixIcon: Icon(Icons.medical_information, color: primaryBlue),
            filled: true,
            fillColor: Colors.white,
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
          decoration: InputDecoration(
            labelText: 'Chẩn đoán',
            prefixIcon: Icon(Icons.psychology, color: primaryBlue),
            filled: true,
            fillColor: Colors.white,
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
          decoration: InputDecoration(
            labelText: 'Tiền khám',
            prefixIcon: Icon(Icons.payments, color: primaryBlue),
            suffixText: 'VNĐ',
            filled: true,
            fillColor: Colors.white,
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
      ],
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
    _animationController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _feeController.dispose();
    super.dispose();
  }
}
