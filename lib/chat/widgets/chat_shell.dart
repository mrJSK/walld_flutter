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
    // DEBUG: Log permission check
    debugPrint('🔐 ChatShell canSend check:');
    debugPrint('  Channel: ${channel.displayName}');
    debugPrint('  CurrentUserId: $currentUserId');
    debugPrint('  AssignedByUid: ${conversation.assignedByUid}');
    debugPrint('  LeadMemberUid: ${conversation.leadMemberUid}');
    debugPrint('  AssignedToUids: ${conversation.assignedToUids}');

    switch (channel) {
      case ChatChannel.teamMembers:
        final result = conversation.canSendToTeamChannel(currentUserId);
        debugPrint('  ✅ Team channel permission: $result');
        return result;

      case ChatChannel.managerCommunication:
        final result = conversation.canSendToAssignedByChannel(currentUserId);
        debugPrint('  ✅ Manager channel permission: $result');
        return result;
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
              // DEBUG: Show permission details
              if (!canSend)
                Tooltip(
                  message: 'Current: $currentUserId\n'
                      'Lead: ${conversation.leadMemberUid}\n'
                      'Assigned: ${conversation.assignedToUids}',
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.info_outline,
                      size: 12,
                      color: Colors.white24,
                    ),
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

              return MessageList(
                messages: msgs,
                currentUserId: currentUserId,
                tenantId: tenantId,
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Input bar
        ChatInputBar(
          enabled: canSend,
          hintText: hint,
          onSendText: (text) async {
            debugPrint('📤 [ChatShell.onSendText] START: "$text"');
            debugPrint('📤 [ChatShell] TenantId: $tenantId');
            debugPrint('📤 [ChatShell] ConversationId: ${conversation.conversationId}');
            debugPrint('📤 [ChatShell] Channel: ${channel.displayName} (${channel.firestoreCollection})');
            debugPrint('📤 [ChatShell] CurrentUserId: $currentUserId');
            debugPrint('📤 [ChatShell] Role: $_roleForCurrentUser');
            debugPrint('📤 [ChatShell] sendTo: ${_resolveSendTo}');

            try {
              await repo.sendTextMessage(
                conversationId: conversation.conversationId,
                channel: channel,
                senderId: currentUserId,
                senderRole: _roleForCurrentUser,
                text: text,
                sendTo: _resolveSendTo,
              );
              debugPrint('✅ [ChatShell.onSendText] SUCCESS');
            } catch (e, st) {
              debugPrint('❌ [ChatShell.onSendText] FAILED: $e');
              debugPrint('📍 [ChatShell.onSendText] STACK: $st');
              rethrow;
            }
          },

          onSendAttachments: ({
            required List<ChatAttachment> attachments,
            String? text,
          }) async {
            debugPrint('📎 Sending file message with ${attachments.length} attachments...');

            // 1. Upload local files (attachments[i].url = local path from picker)
            final uploadedAttachments = await ChatStorageUploader.uploadAll(
              tenantId: tenantId,
              conversationId: conversation.conversationId,
              localAttachments: attachments,
            );

            // 2. Save message in Firestore with ATTCHEDFILES using repository
            await repo.sendFileMessage(
              conversationId: conversation.conversationId,
              channel: channel,
              senderId: currentUserId,
              senderRole: _roleForCurrentUser,
              attachments: uploadedAttachments,
              text: text,
              sendTo: _resolveSendTo,
            );

            debugPrint('✅ File message sent successfully');
          },
        ),
      ],
    );
  }

  String? get _resolveSendTo {
    if (channel == ChatChannel.managerCommunication) {
      return conversation.assignedByUid;
    }
    return null;
  }

  String get _roleForCurrentUser {
    if (currentUserId == conversation.assignedByUid) return 'manager';
    if (currentUserId == conversation.leadMemberUid) return 'lead';
    return 'member';
  }
}
