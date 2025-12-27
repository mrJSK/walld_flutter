class AssignedTaskViewModel {
  final String docId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String groupName;
  final List<String> assignedToUids;
  final int assigneeCount;
  final String? leadMemberId;
  final String assignedByUid;

  AssignedTaskViewModel({
    required this.docId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.groupName,
    required this.assignedToUids,
    required this.assigneeCount,
    required this.leadMemberId,
    required this.assignedByUid,
  });

  // ADD THIS METHOD
  bool isUserLead(String userId) {
    return leadMemberId != null && leadMemberId == userId;
  }

  bool get hasLead => leadMemberId != null && leadMemberId!.isNotEmpty;

  factory AssignedTaskViewModel.fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final status = data['status'] as String? ?? 'PENDING';
    
    // Safe priority extraction
    final customFields = data['customfields'];
    String priority = '';
    if (customFields != null && customFields is Map) {
      priority = customFields['priority'] as String? ?? '';
    }
    
    // Safe due date parsing
    final dueIso = data['duedate'] as String? ?? '';
    DateTime? due;
    if (dueIso.isNotEmpty) {
      try {
        due = DateTime.parse(dueIso);
      } catch (_) {
        due = null;
      }
    }

    final groupName = data['groupname'] as String? ?? '';
    
    // Safe list handling for assigned_to
    List<String> assignedToUids = [];
    final assignedTo = data['assignedto'];
    
    if (assignedTo != null) {
      if (assignedTo is String) {
        if (assignedTo.isNotEmpty) {
          assignedToUids = assignedTo
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } else if (assignedTo is List) {
        assignedToUids = assignedTo
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    
    final assigneeCount = assignedToUids.length;
    final leadMemberId = data['leadmember'] as String?;
    final assignedByUid = data['assignedby'] as String? ?? '';

    return AssignedTaskViewModel(
      docId: docId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: due,
      groupName: groupName,
      assignedToUids: assignedToUids,
      assigneeCount: assigneeCount,
      leadMemberId: leadMemberId,
      assignedByUid: assignedByUid,
    );
  }
}
