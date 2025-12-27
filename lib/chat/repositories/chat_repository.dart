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

  /// Base path: tenants/{tenantId}/CHATS/{conversationId}/{channelCollection}
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

  /// Stream messages in a channel ordered by created_at
  Stream<List<ChatMessage>> streamMessages({
    required String conversationId,
    required ChatChannel channel,
  }) {
    return channelCollection(conversationId, channel)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Send a text message
  Future<void> sendTextMessage({
    required String conversationId,
    required ChatChannel channel,
    required String senderId,
    required String senderRole,
    required String text,
    String? sendTo, // Optional: only for manager communication
    MessageType type = MessageType.text,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderRole: senderRole,
      type: type,
      text: text,
      sendTo: sendTo, // Will be null for team_members_chat
      createdAt: DateTime.now(),
    );

    await channelCollection(conversationId, channel).add(message.toFirestore());
  }

  /// Send a file or progress message with optional text
  Future<void> sendFileMessage({
    required String conversationId,
    required ChatChannel channel,
    required String senderId,
    required String senderRole,
    required String fileUrl,
    required String fileType,
    String? text,
    String? sendTo, // Optional: only for manager communication
    MessageType type = MessageType.file,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderRole: senderRole,
      type: type,
      text: text,
      fileUrl: fileUrl,
      fileType: fileType,
      createdAt: DateTime.now(),
      sendTo: sendTo, // Will be null for team_members_chat
    );

    await channelCollection(conversationId, channel).add(message.toFirestore());
  }
}
