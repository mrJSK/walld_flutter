import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, file, progress }

class ChatAttachment {
  final String url;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final bool compressed;

  ChatAttachment({
    required this.url,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.compressed,
  });

  factory ChatAttachment.fromMap(Map<String, dynamic> map) {
    return ChatAttachment(
      url: map['url'] as String? ?? '',
      name: map['name'] as String? ?? '',
      mimeType: map['type'] as String? ?? '',
      sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
      compressed: map['compressed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'name': name,
      'type': mimeType,
      'size': sizeBytes,
      'compressed': compressed,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final MessageType type;
  final String? text;

  // legacy single file fields – keep for backward compatibility
  final String? fileUrl;
  final String? fileType;

  final List<ChatAttachment> attachments;

  final DateTime createdAt;
  final String? sendTo;
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
    this.attachments = const [],
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

    final timestamp = data['createdat'];
    DateTime createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is String) {
      createdAt = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final rawList = (data['ATTCHED_FILES'] as List?) ?? const [];
    final attachments = rawList
        .whereType<Map<String, dynamic>>()
        .map(ChatAttachment.fromMap)
        .toList();

    return ChatMessage(
      id: doc.id,
      senderId: data['senderid'] as String? ?? '',
      senderRole: data['senderrole'] as String? ?? 'member',
      type: type,
      text: data['text'] as String?,
      fileUrl: data['fileurl'] as String?,
      fileType: data['filetype'] as String?,
      createdAt: createdAt,
      sendTo: data['sendto'] as String?,
      senderName: null,
      attachments: attachments,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'senderid': senderId,
      'senderrole': senderRole,
      'type': type.name,
      'createdat': Timestamp.fromDate(createdAt),
    };

    if (text != null) map['text'] = text;
    if (fileUrl != null) map['fileurl'] = fileUrl;
    if (fileType != null) map['filetype'] = fileType;

    if (attachments.isNotEmpty) {
      map['ATTCHED_FILES'] = attachments.map((a) => a.toMap()).toList();
    }

    if (sendTo != null) map['sendto'] = sendTo;

    return map;
  }
}
