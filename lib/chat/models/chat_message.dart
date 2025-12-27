import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, file, progress }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final MessageType type;
  final String? text;
  final String? fileUrl;
  final String? fileType;
  final DateTime createdAt;
  final String? sendTo;
  
  // Optional: cached sender name (fetched from users collection)
  String? senderName;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.type,
    this.text,
    this.fileUrl,
    this.fileType,
    required this.createdAt,
    this.sendTo,
    this.senderName,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final typeStr = (data['type'] ?? 'text') as String;
    final type = MessageType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MessageType.text,
    );

    final timestamp = data['created_at'];
    DateTime createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is String) {
      createdAt = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return ChatMessage(
      id: doc.id,
      senderId: data['sender_id'] as String? ?? '',
      senderRole: data['sender_role'] as String? ?? 'member',
      type: type,
      text: data['text'] as String?,
      fileUrl: data['file_url'] as String?,
      fileType: data['file_type'] as String?,
      createdAt: createdAt,
      sendTo: data['send_to'] as String?,
      senderName: null, // Will be fetched separately
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender_id': senderId,
      'sender_role': senderRole,
      'type': type.name,
      if (text != null) 'text': text,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
      'created_at': Timestamp.fromDate(createdAt),
      if (sendTo != null) 'send_to': sendTo,
    };
  }
}
