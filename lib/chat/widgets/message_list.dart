// lib/chat/widgets/message_list.dart

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String currentUserId;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMine = msg.senderId == currentUserId;

        return MessageBubble(
          message: msg,
          isMine: isMine,
        );
      },
    );
  }
}
