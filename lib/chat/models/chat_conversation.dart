import 'package:flutter/foundation.dart';

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

  /// Helper: check if a user can send to assignedBy channel (Manager Communication)
  /// Only lead member OR manager can send
  bool canSendToAssignedByChannel(String currentUserUid) {
    final result = currentUserUid == leadMemberUid || currentUserUid == assignedByUid;
    debugPrint('  canSendToAssignedByChannel: $result (current=$currentUserUid, lead=$leadMemberUid, manager=$assignedByUid)');
    return result;
  }

  /// Helper: check if a user can send to team members channel (Team Collaboration)
  /// Any assigned team member OR lead member can send
  bool canSendToTeamChannel(String currentUserUid) {
    // Lead member can always send to team channel
    if (currentUserUid == leadMemberUid) {
      debugPrint('  ✅ User is lead member');
      return true;
    }
    
    // Any assigned team member can send
    final isAssigned = assignedToUids.contains(currentUserUid);
    debugPrint('  ${isAssigned ? "✅" : "❌"} User in assignedToUids: $isAssigned');
    return isAssigned;
  }
}
