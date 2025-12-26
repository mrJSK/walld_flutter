// lib/chat/widgets/chat_shell.dart

import 'package:flutter/material.dart';

import '../models/chat_channel.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import 'chat_input_bar.dart';
import 'message_list.dart';

class ChatShell extends StatelessWidget {
  final String tenantId;
  final ChatConversation conversation;
  final ChatChannel channel;
  final String currentUserId;

  const ChatShell({
    super.key,
    required this.tenantId,
    required this.conversation,
    required this.channel,
    required this.currentUserId,
  });

  bool get _canSend {
    switch (channel) {
      case ChatChannel.teamMembers:
        return conversation.canSendToTeamChannel(currentUserId);
      case ChatChannel.assignedBy:
        return conversation.canSendToAssignedByChannel(currentUserId);
    }
  }

  String get _hint {
    switch (channel) {
      case ChatChannel.teamMembers:
        return 'Message team members';
      case ChatChannel.assignedBy:
        return 'Ask doubt / share progress with manager';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ChatRepository(tenantId: tenantId);

    return Column(
      children: [
        // header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                channel.displayName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              if (!_canSend)
                const Text(
                  '(read only)',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // messages
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: repo.streamMessages(
              conversationId: conversation.conversationId,
              channel: channel,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    strokeWidth: 2,
                  ),
                );
              }

              final msgs = snapshot.data ?? const <ChatMessage>[];

              if (msgs.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet.\nStart the conversation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                );
              }

              return MessageList(
                messages: msgs,
                currentUserId: currentUserId,
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        ChatInputBar(
          enabled: _canSend,
          hintText: _hint,
          onSend: (text) => repo.sendTextMessage(
            conversationId: conversation.conversationId,
            channel: channel,
            senderId: currentUserId,
            senderRole: _roleForCurrentUser(),
            text: text,
          ),
        ),
      ],
    );
  }

  String _roleForCurrentUser() {
    if (currentUserId == conversation.assignedByUid) return 'manager';
    if (currentUserId == conversation.leadMemberUid) return 'lead';
    return 'member';
  }
}
