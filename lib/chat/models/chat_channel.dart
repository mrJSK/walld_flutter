// lib/chat/models/chat_channel.dart

/// Defines the type of chat channel
enum ChatChannel {
  /// Chat among all assigned team members
  teamMembers,

  /// Chat between lead member and assigned_by user
  assignedBy,
}

extension ChatChannelExt on ChatChannel {
  String get firestoreCollection {
    switch (this) {
      case ChatChannel.teamMembers:
        return 'team_members_chat';
      case ChatChannel.assignedBy:
        return 'assigned_by_chat';
    }
  }

  String get displayName {
    switch (this) {
      case ChatChannel.teamMembers:
        return 'Team Chat';
      case ChatChannel.assignedBy:
        return 'Manager Chat';
    }
  }
}
