import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_application/main.dart';
import 'package:patient_application/models/doctor.dart';
import 'package:uuid/uuid.dart';

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
  List<Doctor> _doctors = [];
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _notesController = TextEditingController();

  // Clinic location options
  final List<String> _clinicLocations = [
    'Phòng khám Đa khoa ABC, 123 Đường Lê Lợi, Quận 1, TP.HCM',
    'Bệnh viện Quốc tế XYZ, 456 Đường Nguyễn Huệ, Quận 3, TP.HCM',
    'Trung tâm Y tế DEF, 789 Đường Võ Văn Tần, Quận 5, TP.HCM',
  ];
  String _selectedLocation =
      'Phòng khám Đa khoa ABC, 123 Đường Lê Lợi, Quận 1, TP.HCM';

  @override
  void initState() {
    super.initState();
    _loadDoctors();

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

        // If there are no doctors in the database, create some sample data for testing
        if (_doctors.isEmpty) {
          _doctors = [
            Doctor(
              id: const Uuid().v4(),
              name: 'Nguyễn Văn A',
              specialty: 'Nội khoa',
              avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
              bio:
                  'Bác sĩ chuyên khoa Nội tổng quát với hơn 15 năm kinh nghiệm',
            ),
            Doctor(
              id: const Uuid().v4(),
              name: 'Trần Thị B',
              specialty: 'Da liễu',
              avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
              bio: 'Chuyên gia về các bệnh lý da liễu và thẩm mỹ da',
            ),
            Doctor(
              id: const Uuid().v4(),
              name: 'Lê Hoàng C',
              specialty: 'Tim mạch',
              avatarUrl: 'https://randomuser.me/api/portraits/men/67.jpg',
              bio: 'Bác sĩ Tim mạch, tốt nghiệp Đại học Y Dược TP.HCM',
            ),
          ];
        }

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
      // If the doctors table doesn't exist yet, continue with sample data
      debugPrint('Error loading doctors: $e');
      setState(() {
        _doctors = [
          Doctor(
            id: '1',
            name: 'Nguyễn Văn A',
            specialty: 'Nội khoa',
            avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
            bio: 'Bác sĩ chuyên khoa Nội tổng quát với hơn 15 năm kinh nghiệm',
          ),
          Doctor(
            id: '2',
            name: 'Trần Thị B',
            specialty: 'Da liễu',
            avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
            bio: 'Chuyên gia về các bệnh lý da liễu và thẩm mỹ da',
          ),
          Doctor(
            id: '3',
            name: 'Lê Hoàng C',
            specialty: 'Tim mạch',
            avatarUrl: 'https://randomuser.me/api/portraits/men/67.jpg',
            bio: 'Bác sĩ Tim mạch, tốt nghiệp Đại học Y Dược TP.HCM',
          ),
        ];

        _selectedDoctor ??= _doctors.first;
      });
    } finally {
      setState(() => _isLoadingDoctors = false);
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
          'location': _selectedLocation,
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
          _isLoadingDoctors
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
                                            maxLines:
                                                3, // Giới hạn số dòng cho bio
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
                                flex: 1, // Xác định tỉ lệ chia rõ ràng
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
                              const SizedBox(
                                width: 12,
                              ), // Giảm khoảng cách để tránh tràn
                              Expanded(
                                flex: 1, // Xác định tỉ lệ chia rõ ràng
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
                          DropdownButtonFormField<String>(
                            value: _selectedLocation,
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
                            isDense: true, // Thêm dòng này giúp giảm chiều cao
                            menuMaxHeight: 300,
                            icon: const Icon(Icons.arrow_drop_down),
                            items:
                                _clinicLocations.map((String location) {
                                  return DropdownMenuItem<String>(
                                    value: location,
                                    child: Text(
                                      location,
                                      maxLines: 1, // Giới hạn chỉ 1 dòng
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLocation = newValue;
                                });
                              }
                            },
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Vui lòng chọn địa điểm khám'
                                        : null,
                          ),

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
