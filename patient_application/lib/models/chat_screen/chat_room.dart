import 'package:flutter/foundation.dart';

class ChatRoom {
  final String id;
  final String patientId;
  final String doctorId;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;

  // Optional fields that can come from joins
  final Map<String, dynamic>? doctorProfile;

  ChatRoom({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    this.doctorProfile,
  });

  // Factory constructor to create a ChatRoom from a map (json)
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    debugPrint('Converting JSON to ChatRoom: $json');

    return ChatRoom(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      lastMessage: json['last_message'],
      lastMessageTime:
          json['last_message_time'] != null
              ? DateTime.parse(json['last_message_time'])
              : DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      doctorProfile:
          json['doctors'] != null
              ? json['doctors'] as Map<String, dynamic>
              : null,
    );
  }

  // Method to convert ChatRoom object to a map (json)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a copy of the ChatRoom with updated fields
  ChatRoom copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? createdAt,
    Map<String, dynamic>? doctorProfile,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      doctorProfile: doctorProfile ?? this.doctorProfile,
    );
  }
}
