import 'package:flutter/material.dart';

import '../models/chat_channel.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/chat_storage_uploader.dart';
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

  bool get canSend {
    switch (channel) {
      case ChatChannel.teamMembers:
        return conversation.canSendToTeamChannel(currentUserId);
      case ChatChannel.managerCommunication:
        return conversation.canSendToAssignedByChannel(currentUserId);
    }
  }

  String get hint {
    switch (channel) {
      case ChatChannel.teamMembers:
        return 'Message team members';
      case ChatChannel.managerCommunication:
        return 'Escalate to manager / Share progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ChatRepository(tenantId: tenantId);

    return Column(
      children: [
        // Header
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
              if (!canSend)
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

        // Messages
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    strokeWidth: 2,
                  ),
                );
              }

              final msgs = snapshot.data ?? const <ChatMessage>[];

              if (msgs.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet. Start the conversation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                );
              }

              // In the MessageList widget call
              return MessageList(
                messages: msgs,
                currentUserId: currentUserId,
                tenantId: tenantId, // ✅ ADD THIS
              );

            },
          ),
        ),

        const SizedBox(height: 8),

        // Input bar
        ChatInputBar(
          enabled: canSend,
          hintText: hint,
          onSendText: (text) => repo.sendTextMessage(
            conversationId: conversation.conversationId,
            channel: channel,
            senderId: currentUserId,
            senderRole: _roleForCurrentUser(),
            text: text,
            sendTo: _resolveSendTo(),
          ),
          onSendAttachments: ({
            required List<ChatAttachment> attachments,
            String? text,
          }) async {
            // 1. Upload local files (attachments[i].url = local path from picker)
            final uploadedAttachments = await ChatStorageUploader.uploadAll(
              tenantId: tenantId,
              conversationId: conversation.conversationId,
              localAttachments: attachments,
            );

            // 2. Save message in Firestore with ATTCHED_FILES using repository
            await repo.sendFileMessage(
              conversationId: conversation.conversationId,
              channel: channel,
              senderId: currentUserId,
              senderRole: _roleForCurrentUser(),
              attachments: uploadedAttachments,
              text: text,
              sendTo: _resolveSendTo(),
            );
          },
        ),

      ],
    );
  }

  String? _resolveSendTo() {
    if (channel == ChatChannel.managerCommunication) {
      return conversation.assignedByUid;
    }
    return null;
  }

  String _roleForCurrentUser() {
    if (currentUserId == conversation.assignedByUid) return 'manager';
    if (currentUserId == conversation.leadMemberUid) return 'lead';
    return 'member';
  }
}
