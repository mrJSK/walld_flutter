import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_channel.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final String tenantId;
  final FirebaseFirestore db;

  ChatRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> channelCollection(
    String conversationId,
    ChatChannel channel,
  ) {
    return db
        .collection('tenants')
        .doc(tenantId)
        .collection('CHATS')
        .doc(conversationId)
        .collection(channel.firestoreCollection);
  }

  Stream<List<ChatMessage>> streamMessages({
    required String conversationId,
    required ChatChannel channel,
  }) {
    return channelCollection(conversationId, channel)
        .orderBy('createdat', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required ChatChannel channel,
    required String senderId,
    required String senderRole,
    required String text,
    String? sendTo,
    MessageType type = MessageType.text,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderRole: senderRole,
      type: type,
      text: text,
      createdAt: DateTime.now(),
      sendTo: sendTo,
    );

    await channelCollection(conversationId, channel)
        .add(message.toFirestore());
  }

  Future<void> sendFileMessage({
    required String conversationId,
    required ChatChannel channel,
    required String senderId,
    required String senderRole,
    required List<ChatAttachment> attachments,
    String? text,
    String? sendTo,
    MessageType type = MessageType.file,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderRole: senderRole,
      type: type,
      text: text,
      createdAt: DateTime.now(),
      sendTo: sendTo,
      attachments: attachments,
    );

    await channelCollection(conversationId, channel)
        .add(message.toFirestore());
  }
}
