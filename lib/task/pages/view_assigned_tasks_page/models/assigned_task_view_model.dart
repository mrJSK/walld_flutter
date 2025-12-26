// lib/task/pages/view_assigned_tasks_page/models/assigned_task_view_model.dart

class AssignedTaskViewModel {
  final String docId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String groupName;

  /// Raw comma-separated string from Firestore (`assigned_to`)
  final String assignedToRaw;

  /// Parsed list of assignee UIDs
  final List<String> assignedToUids;

  final int assigneeCount;

  /// UID of lead member (can be null)
  final String? leadMemberId;

  /// UID of user who assigned the task
  final String? assignedByUid;

  AssignedTaskViewModel({
    required this.docId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.groupName,
    required this.assignedToRaw,
    required this.assignedToUids,
    required this.assigneeCount,
    required this.leadMemberId,
    required this.assignedByUid,
  });

  factory AssignedTaskViewModel.fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final title = (data['title'] ?? '') as String;
    final description = (data['description'] ?? '') as String;
    final status = (data['status'] ?? 'PENDING') as String;
    final priority =
        (data['custom_fields']?['priority'] ?? '').toString().toUpperCase();

    final dueIso = (data['due_date'] ?? '') as String;
    DateTime? due;
    if (dueIso.isNotEmpty) {
      try {
        due = DateTime.parse(dueIso);
      } catch (_) {
        due = null;
      }
    }

    final groupName = (data['group_name'] ?? '') as String;

    final assignedTo = (data['assigned_to'] ?? '') as String;
    final assignedToUids = assignedTo.isEmpty
        ? <String>[]
        : assignedTo.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final assigneeCount = assignedToUids.length;

    final leadMemberId = data['lead_member'] as String?;
    final assignedByUid = data['assigned_by'] as String?;

    return AssignedTaskViewModel(
      docId: docId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: due,
      groupName: groupName,
      assignedToRaw: assignedTo,
      assignedToUids: assignedToUids,
      assigneeCount: assigneeCount,
      leadMemberId: leadMemberId,
      assignedByUid: assignedByUid,
    );
  }

  bool get isGroupTask => groupName.isNotEmpty && assigneeCount > 1;
}
