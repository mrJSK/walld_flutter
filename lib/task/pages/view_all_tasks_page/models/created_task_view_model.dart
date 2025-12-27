class CreatedTaskViewModel {
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

  CreatedTaskViewModel({
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
  });

  factory CreatedTaskViewModel.fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final status = data['status'] as String? ?? 'PENDING';
    
    // Safe priority extraction
    final customFields = data['custom_fields'];
    String priority = '';
    if (customFields != null && customFields is Map) {
      priority = customFields['priority'] as String? ?? '';
    }
    
    // Safe due date parsing
    final dueIso = data['due_date'] as String? ?? '';
    DateTime? due;
    if (dueIso.isNotEmpty) {
      try {
        due = DateTime.parse(dueIso);
      } catch (_) {
        due = null;
      }
    }

    final groupName = data['group_name'] as String? ?? '';
    
    // FIXED: Safe list handling for assigned_to
    List<String> assignedToUids = [];
    final assignedTo = data['assigned_to'];
    
    if (assignedTo != null) {
      if (assignedTo is String) {
        // If it's a comma-separated string
        if (assignedTo.isNotEmpty) {
          assignedToUids = assignedTo
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } else if (assignedTo is List) {
        // If it's already a list (from Firestore array)
        assignedToUids = assignedTo
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    
    final assigneeCount = assignedToUids.length;
    final leadMemberId = data['lead_member'] as String?;

    return CreatedTaskViewModel(
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
    );
  }

  bool get hasLead => leadMemberId != null && leadMemberId!.isNotEmpty;
}
