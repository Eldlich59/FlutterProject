import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_application/main.dart';
import 'package:patient_application/models/doctor.dart';
import 'package:patient_application/models/hospital.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key, this.preselectedDoctor});

  final Doctor? preselectedDoctor;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingDoctors = true;
  bool _isLoadingHospitals = true;
  List<Doctor> _doctors = [];
  List<Hospital> _hospitals = [];
  Doctor? _selectedDoctor;
  Hospital? _selectedHospital;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadHospitals();

    if (widget.preselectedDoctor != null) {
      _selectedDoctor = widget.preselectedDoctor;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoadingDoctors = true);
    try {
      // Query doctors from your database
      final doctorsData = await supabase.from('doctors').select();
      setState(() {
        _doctors =
            doctorsData.map<Doctor>((json) => Doctor.fromJson(json)).toList();

        // If a doctor was preselected, make sure it's in our list
        if (widget.preselectedDoctor != null &&
            !_doctors.any(
              (doctor) => doctor.id == widget.preselectedDoctor!.id,
            )) {
          _doctors.add(widget.preselectedDoctor!);
        }

        // Set default selected doctor
        if (_selectedDoctor == null && _doctors.isNotEmpty) {
          _selectedDoctor = _doctors.first;
        }
      });
    } catch (e) {
      // Show error message instead of using sample data
      debugPrint('Error loading doctors: $e');
      setState(() {
        _doctors = [];
        _selectedDoctor = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể tải danh sách bác sĩ. Vui lòng kiểm tra kết nối và thử lại sau.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _loadHospitals() async {
    setState(() => _isLoadingHospitals = true);
    try {
      // Query hospitals from the database
      final hospitalsData = await supabase
          .from('hospitals')
          .select()
          .eq('is_active', true)
          .order('name');

      setState(() {
        _hospitals =
            hospitalsData
                .map<Hospital>((json) => Hospital.fromJson(json))
                .toList();

        if (_hospitals.isNotEmpty) {
          _selectedHospital = _hospitals.first;
        }
      });
    } catch (e) {
      // Show error message instead of using sample data
      debugPrint('Error loading hospitals: $e');
      setState(() {
        _hospitals = [];
        _selectedHospital = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể tải danh sách bệnh viện/phòng khám. Vui lòng kiểm tra kết nối và thử lại sau.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingHospitals = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn bác sĩ')));
      return;
    }

    if (_selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa điểm khám')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        // Combine date and time
        final appointmentDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Create appointment in database
        await supabase.from('appointments').insert({
          'patient_id': userId,
          'doctor_id': _selectedDoctor!.id,
          'doctor_name': _selectedDoctor!.name,
          'doctor_specialty': _selectedDoctor!.specialty,
          'doctor_avatar_url': _selectedDoctor!.avatarUrl,
          'date_time': appointmentDateTime.toIso8601String(),
          'status': 'scheduled',
          'location': _selectedHospital!.address,
          'hospital_id': _selectedHospital!.id,
          'hospital_name': _selectedHospital!.name,
          'notes': _notesController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đặt lịch khám thành công')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        debugPrint('Error booking appointment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi đặt lịch: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch khám')),
      resizeToAvoidBottomInset: true,
      body:
          _isLoadingDoctors || _isLoadingHospitals
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16), // Start with some padding
                          // Doctor selection
                          Text(
                            'Chọn bác sĩ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Doctor>(
                            value: _selectedDoctor,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            isExpanded: true,
                            items:
                                _doctors.map((Doctor doctor) {
                                  return DropdownMenuItem<Doctor>(
                                    value: doctor,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          backgroundImage:
                                              doctor.avatarUrl != null
                                                  ? NetworkImage(
                                                    doctor.avatarUrl!,
                                                  )
                                                  : null,
                                          radius: 16,
                                          child:
                                              doctor.avatarUrl == null
                                                  ? const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'BS. ${doctor.name}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (Doctor? newValue) {
                              setState(() {
                                _selectedDoctor = newValue;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Vui lòng chọn bác sĩ'
                                        : null,
                          ),
                          if (_selectedDoctor != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                          _selectedDoctor!.avatarUrl != null
                                              ? NetworkImage(
                                                _selectedDoctor!.avatarUrl!,
                                              )
                                              : null,
                                      radius: 30,
                                      child:
                                          _selectedDoctor!.avatarUrl == null
                                              ? const Icon(Icons.person)
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BS. ${_selectedDoctor!.name}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedDoctor!.specialty,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _selectedDoctor!.bio ??
                                                'Không có thông tin',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Date and Time selection
                          Text(
                            'Chọn ngày và giờ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      prefixIcon: const Icon(
                                        Icons.calendar_today,
                                      ),
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () => _selectTime(context),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      prefixIcon: const Icon(Icons.access_time),
                                    ),
                                    child: Text(_selectedTime.format(context)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Location selection
                          Text(
                            'Chọn địa điểm khám',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Hospital>(
                            value: _selectedHospital,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              prefixIcon: const Icon(Icons.location_on),
                            ),
                            isExpanded: true,
                            isDense: true,
                            menuMaxHeight: 300,
                            icon: const Icon(Icons.arrow_drop_down),
                            items:
                                _hospitals.map((Hospital hospital) {
                                  return DropdownMenuItem<Hospital>(
                                    value: hospital,
                                    child: Text(
                                      '${hospital.name}, ${hospital.address}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (Hospital? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedHospital = newValue;
                                });
                              }
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Vui lòng chọn địa điểm khám'
                                        : null,
                          ),

                          if (_selectedHospital != null &&
                              (_selectedHospital!.description != null ||
                                  _selectedHospital!.operatingHours !=
                                      null)) ...[
                            const SizedBox(height: 8),
                            Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_selectedHospital!.description != null)
                                      Text(
                                        _selectedHospital!.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    if (_selectedHospital!.description !=
                                            null &&
                                        _selectedHospital!.operatingHours !=
                                            null)
                                      const SizedBox(height: 8),
                                    if (_selectedHospital!.operatingHours !=
                                        null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _selectedHospital!.operatingHours!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (_selectedHospital!.phoneNumber != null)
                                      const SizedBox(height: 8),
                                    if (_selectedHospital!.phoneNumber != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _selectedHospital!.phoneNumber!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Notes
                          Text(
                            'Ghi chú (không bắt buộc)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              hintText: 'Nhập triệu chứng hoặc lý do khám',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 3,
                          ),

                          // Submit button
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 100,
                              top: 32,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _bookAppointment,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text(
                                          'Xác nhận đặt lịch',
                                          style: TextStyle(fontSize: 16),
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
    );
  }
}
