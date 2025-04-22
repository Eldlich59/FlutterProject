import 'package:flutter/material.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorAvatarUrl;
  final DateTime dateTime;
  final String status; // 'scheduled', 'completed', 'cancelled', 'rescheduled'
  final String? notes;
  final String location;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorAvatarUrl,
    required this.dateTime,
    required this.status,
    this.notes,
    required this.location,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      doctorSpecialty: json['doctor_specialty'],
      doctorAvatarUrl: json['doctor_avatar_url'],
      dateTime: DateTime.parse(json['date_time']),
      status: json['status'],
      notes: json['notes'],
      location: json['location'],
    );
  }

  // Formatting helper methods
  String get formattedDateTime {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String get formattedTime {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color getStatusColor() {
    switch (status) {
      case 'scheduled':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String getStatusText() {
    switch (status) {
      case 'scheduled':
        return 'Đã lên lịch';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'rescheduled':
        return 'Đã đổi lịch';
      default:
        return 'Không xác định';
    }
  }

  bool get isUpcoming =>
      status == 'scheduled' && dateTime.isAfter(DateTime.now());
}
