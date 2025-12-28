import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_channel.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final String tenantId;
  final FirebaseFirestore db;

  ChatRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _channelCollection(
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
    return _channelCollection(conversationId, channel)
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
    debugPrint('🔥 [Repo.sendTextMessage] START');
    debugPrint('🔥 [Repo] Tenant: $tenantId');
    debugPrint('🔥 [Repo] Conversation: $conversationId');
    debugPrint('🔥 [Repo] Channel: ${channel.firestoreCollection}');
    debugPrint('🔥 [Repo] Sender: $senderId ($senderRole)');
    debugPrint('🔥 [Repo] Text: "$text"');
    debugPrint('🔥 [Repo] sendTo: $sendTo');

    try {
      final message = ChatMessage(
        id: '',
        senderId: senderId,
        senderRole: senderRole,
        type: type,
        text: text,
        createdAt: DateTime.now(),
        sendTo: sendTo,
      );

      debugPrint('🔥 [Repo] Full Firestore path:');
      final collection = _channelCollection(conversationId, channel);
      debugPrint('🔥 [Repo] PATH: tenants/$tenantId/CHATS/$conversationId/${channel.firestoreCollection}');
      
      debugPrint('🔥 [Repo] Message data: ${message.toFirestore()}');

      final docRef = await collection.add(message.toFirestore());
      debugPrint('✅ [Repo.sendTextMessage] SUCCESS - DocID: ${docRef.id}');
    } catch (e, stackTrace) {
      debugPrint('❌ [Repo.sendTextMessage] FIRESTORE ERROR: $e');
      debugPrint('📍 [Repo.sendTextMessage] FULL STACK: $stackTrace');
      rethrow;
    }
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
    try {
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

      debugPrint('📎 Sending file message to Firestore...');
      debugPrint('Attachments: ${attachments.length}');
      debugPrint('Path: tenants/$tenantId/CHATS/$conversationId/${channel.firestoreCollection}');

      final data = message.toFirestore();
      debugPrint('Message data: $data');

      await _channelCollection(conversationId, channel).add(data);

      debugPrint('✅ File message saved to Firestore');
    } catch (e, stackTrace) {
      debugPrint('❌ Firestore error (file): $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
