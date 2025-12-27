/// Defines the type of chat channel
enum ChatChannel {
  /// Chat among all assigned team members (peer-to-peer)
  teamMembers,

  /// Chat between lead/member and manager (escalation)
  managerCommunication,
}

extension ChatChannelExt on ChatChannel {
  String get firestoreCollection {
    switch (this) {
      case ChatChannel.teamMembers:
        return 'team_members_chat';
      case ChatChannel.managerCommunication:
        return 'manager_communication_chat';
    }
  }

  String get displayName {
    switch (this) {
      case ChatChannel.teamMembers:
        return 'Team Collaboration';
      case ChatChannel.managerCommunication:
        return 'Manager Communication';
    }
  }
}
