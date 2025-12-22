import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskFieldType { text, dropdown, date }

TaskFieldType _parseFieldType(String raw) {
  switch (raw) {
    case 'dropdown':
      return TaskFieldType.dropdown;
    case 'date':
      return TaskFieldType.date;
    case 'text':
    default:
      return TaskFieldType.text;
  }
}

class TaskFormFieldConfig {
  final String id;
  final String label;
  final bool required;
  final TaskFieldType type;
  final List<String> options;

  TaskFormFieldConfig({
    required this.id,
    required this.label,
    required this.required,
    required this.type,
    this.options = const [],
  });

  factory TaskFormFieldConfig.fromMap(Map<String, dynamic> map) {
    return TaskFormFieldConfig(
      id: map['id'] as String,
      label: (map['label'] as String?) ?? map['id'] as String,
      required: (map['required'] as bool?) ?? false,
      type: _parseFieldType(map['type'] as String? ?? 'text'),
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'required': required,
      'type': switch (type) {
        TaskFieldType.text => 'text',
        TaskFieldType.dropdown => 'dropdown',
        TaskFieldType.date => 'date',
      },
      'options': options,
    };
  }
}

class TaskFormDefinition {
  final String name;
  final String description;
  final List<TaskFormFieldConfig> fields;

  TaskFormDefinition({
    required this.name,
    required this.description,
    required this.fields,
  });

  factory TaskFormDefinition.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final schema = data['schema'] as Map<String, dynamic>? ?? {};
    final List<dynamic> rawFields = schema['fields'] as List<dynamic>? ?? [];
    final fields = rawFields
        .map((f) => TaskFormFieldConfig.fromMap(f as Map<String, dynamic>))
        .toList();

    return TaskFormDefinition(
      name: data['name'] as String? ?? 'Create Task',
      description:
          data['description'] as String? ?? 'Form to create and assign tasks',
      fields: fields,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'schema': {
        'fields': fields.map((f) => f.toMap()).toList(),
      },
    };
  }

  factory TaskFormDefinition.fromCacheJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final schema = data['schema'] as Map<String, dynamic>? ?? {};
    final List<dynamic> rawFields = schema['fields'] as List<dynamic>? ?? [];
    final fields = rawFields
        .map((f) => TaskFormFieldConfig.fromMap(f as Map<String, dynamic>))
        .toList();

    return TaskFormDefinition(
      name: data['name'] as String? ?? 'Create Task',
      description:
          data['description'] as String? ?? 'Form to create and assign tasks',
      fields: fields,
    );
  }
}

class TaskFormRepository {
  static const _prefsFormKey = 'cached_task_creation_form';

  final String tenantId;

  TaskFormRepository({required this.tenantId});

  Future<TaskFormDefinition> loadCreateTaskFormOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsFormKey);
    if (cached != null) {
      return TaskFormDefinition.fromCacheJson(cached);
    }

    final docRef = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('forms')
        .doc('task_creation');

    final snap = await docRef.get();
    final def = TaskFormDefinition.fromDoc(snap);

    await prefs.setString(_prefsFormKey, jsonEncode(def.toMap()));
    return def;
  }

  Future<void> createTask({
    required String createdBy,
    required Map<String, dynamic> values,
  }) async {
    final tasksCol = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('tasks');

    final now = DateTime.now();
    final core = <String, dynamic>{
      'title': values['title'] ?? '',
      'description': values['description'] ?? '',
      'status': 'PENDING',
      'created_by': createdBy,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    if (values['dueDate'] != null && values['dueDate'] is DateTime) {
      core['due_date'] = (values['dueDate'] as DateTime).toIso8601String();
    }

    final custom = Map<String, dynamic>.from(values)
      ..remove('title')
      ..remove('description')
      ..remove('dueDate');

    if (custom.isNotEmpty) {
      core['custom_fields'] = custom;
    }

    await tasksCol.add(core);
  }
}
