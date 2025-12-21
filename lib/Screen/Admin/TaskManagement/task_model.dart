import 'package:cloud_firestore/cloud_firestore.dart';

class TaskMeta {
  String id;
  String title;
  String description;
  String status; // HARDCODED enum values
  String priority;
  String? assigneeId;
  String? assigneeName;
  DateTime? dueDate;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? customFields; // DYNAMIC per company

  TaskMeta({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.assigneeName,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.customFields,
  });

  factory TaskMeta.fromMap(String id, Map<String, dynamic> map) {
    return TaskMeta(
      id: id,
      title: map['title'] ?? 'Untitled Task',
      description: map['description'] ?? '',
      status: map['status'] ?? 'PENDING',
      priority: map['priority'] ?? 'MEDIUM',
      assigneeId: map['assigneeId'],
      assigneeName: map['assigneeName'],
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customFields: map['custom'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (assigneeName != null) 'assigneeName': assigneeName,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (customFields != null) 'custom': customFields,
    };
  }
}
