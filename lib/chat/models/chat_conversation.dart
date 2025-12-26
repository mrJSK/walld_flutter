// lib/chat/models/chat_conversation.dart

/// Metadata about a conversation (task context)
class ChatConversation {
  final String conversationId; // typically the task docId
  final String taskTitle;
  final String assignedByUid;
  final List<String> assignedToUids;
  final String? leadMemberUid;
  final String? groupName;
  final DateTime? dueDate;

  ChatConversation({
    required this.conversationId,
    required this.taskTitle,
    required this.assignedByUid,
    required this.assignedToUids,
    this.leadMemberUid,
    this.groupName,
    this.dueDate,
  });

  /// Helper: check if a user can send to assignedBy channel
  bool canSendToAssignedByChannel(String currentUserUid) {
    return currentUserUid == leadMemberUid || currentUserUid == assignedByUid;
  }

  /// Helper: check if a user can send to team members channel
  bool canSendToTeamChannel(String currentUserUid) {
    return assignedToUids.contains(currentUserUid);
  }
}
