class AssignmentData {
  final String assignmentType; // 'subordinate_unit' or 'team_member'
  final String? selectedNodeId; // for subordinate_unit
  final List<String> selectedUserIds; // for team_member
  final String? groupName; // for multi-user team_member
  final String? leadMemberId; // ← NEW: lead member UID for groups
  final Map<String, String> nodeToHeadUserMap; // nodeId -> headUserId mapping

  AssignmentData({
    required this.assignmentType,
    this.selectedNodeId,
    this.selectedUserIds = const [],
    this.groupName,
    this.leadMemberId,
    this.nodeToHeadUserMap = const {},
  });

  bool get isValid {
    if (assignmentType == 'subordinate_unit') {
      return selectedNodeId != null && selectedNodeId != 'none';
    } else if (assignmentType == 'team_member') {
      if (selectedUserIds.isEmpty) return false;
      
      // If multiple users, group name AND lead member are required
      if (selectedUserIds.length > 1) {
        return groupName != null && 
               groupName!.trim().isNotEmpty &&
               leadMemberId != null &&
               selectedUserIds.contains(leadMemberId);
      }
      return true;
    }
    return false;
  }
}
