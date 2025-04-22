import 'package:flutter/material.dart';
import 'package:patient_application/models/appointment.dart';
import 'package:patient_application/main.dart';
import 'package:patient_application/screens/appointment/book_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() => _isLoading = true);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        return;
      }

      try {
        final appointmentsData = await supabase
            .from('appointments')
            .select()
            .eq('patient_id', userId)
            .order('date_time', ascending: true);

        setState(() {
          _appointments =
              appointmentsData
                  .map<Appointment>((json) => Appointment.fromJson(json))
                  .toList();
        });
      } catch (e) {
        // Check if the error is about missing table
        if (e.toString().contains(
          'relation "public.appointments" does not exist',
        )) {
          debugPrint('Bảng appointments chưa được tạo trong cơ sở dữ liệu');
          setState(() => _appointments = []);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Hệ thống lịch hẹn đang được thiết lập. Vui lòng thử lại sau.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          debugPrint('Lỗi khi tải lịch hẹn: $e');
          setState(() => _appointments = []);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToBookAppointment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
    );

    if (result == true) {
      // Reload appointments if a new one was added
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn của tôi')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _appointments.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn chưa có lịch hẹn nào',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _navigateToBookAppointment,
                      icon: const Icon(Icons.add),
                      label: const Text('Đặt lịch khám'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        // Show appointment details
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Doctor avatar
                                CircleAvatar(
                                  backgroundImage:
                                      appointment.doctorAvatarUrl != null
                                          ? NetworkImage(
                                            appointment.doctorAvatarUrl!,
                                          )
                                          : null,
                                  child:
                                      appointment.doctorAvatarUrl == null
                                          ? const Icon(Icons.person)
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                // Doctor info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BS. ${appointment.doctorName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        appointment.doctorSpecialty,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: appointment
                                        .getStatusColor()
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    appointment.getStatusText(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appointment.getStatusColor(),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Date and time
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.formattedDate,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.formattedTime,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    appointment.location,
                                    style: TextStyle(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            // Show notes if available
                            if (appointment.notes != null &&
                                appointment.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.note,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      appointment.notes!,
                                      style: TextStyle(color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToBookAppointment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
