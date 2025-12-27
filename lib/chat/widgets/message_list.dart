import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String currentUserId;
  final String tenantId;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          tenantId: tenantId,
        );
      },
    );
  }
}
