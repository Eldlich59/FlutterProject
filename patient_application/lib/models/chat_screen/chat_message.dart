import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String?
  senderType; // Thêm trường senderType để phân biệt loại người gửi
  final String message;
  final DateTime createdAt;
  final bool isRead;

  // Optional fields for attached files, etc. could be added here
  final String? attachmentUrl;
  final String? attachmentType;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    this.senderType, // 'doctor' hoặc 'patient'
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
  });

  // Factory constructor to create a ChatMessage from a map (json)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    debugPrint('Converting JSON to ChatMessage: $json');

    return ChatMessage(
      id: json['id'],
      chatRoomId: json['chat_room_id'],
      senderId: json['sender_id'],
      senderType: json['sender_type'], // Đọc trường sender_type từ JSON
      message: json['message'] ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url'],
      attachmentType: json['attachment_type'],
    );
  }

  // Method to convert ChatMessage object to a map (json)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'sender_type': senderType, // Thêm trường sender_type vào JSON
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
    };
  }

  // Create a copy of the ChatMessage with updated fields
  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderType, // Thêm senderType vào copyWith
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType, // Giữ lại senderType khi copy
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }
}
