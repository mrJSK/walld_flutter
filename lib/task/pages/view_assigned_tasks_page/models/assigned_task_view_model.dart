// lib/task/pages/view_assigned_tasks_page/models/assigned_task_view_model.dart

class AssignedTaskViewModel {
  final String docId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final String groupName;
  final String assignedToRaw; // comma-separated uids
  final int assigneeCount;
  final String? leadMemberId;

  AssignedTaskViewModel({
    required this.docId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.groupName,
    required this.assignedToRaw,
    required this.assigneeCount,
    required this.leadMemberId,
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
    final assigneeCount =
        assignedTo.isEmpty ? 0 : assignedTo.split(',').length;

    final leadMemberId = data['lead_member'] as String?;

    return AssignedTaskViewModel(
      docId: docId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: due,
      groupName: groupName,
      assignedToRaw: assignedTo,
      assigneeCount: assigneeCount,
      leadMemberId: leadMemberId,
    );
  }

  bool get isGroupTask => groupName.isNotEmpty && assigneeCount > 1;
}
