import 'dart:convert';

/* High-level form definition */

class FormSchemaMeta {
  String formId;
  String name;
  String description;
  List<FormFieldMeta> fields;

  FormSchemaMeta({
    required this.formId,
    required this.name,
    required this.description,
    required this.fields,
  });

  factory FormSchemaMeta.fromFirestore(
      String id, Map<String, dynamic> map) {
    final schema = map['schema'] ?? {};
    final fieldsJson = (schema['fields'] ?? []) as List<dynamic>;

    return FormSchemaMeta(
      formId: id,
      name: map['name'] ?? id,
      description: map['description'] ?? '',
      fields: fieldsJson
          .map((e) => FormFieldMeta.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final schema = {
      'formId': formId,
      'version': 1,
      'fields': fields.map((f) => f.toMap()).toList(),
    };

    return {
      'name': name,
      'description': description,
      'schema': schema,
    };
  }

  static FormSchemaMeta defaultUserRegistration() {
    return FormSchemaMeta(
      formId: 'user_registration',
      name: 'User Registration Form',
      description: 'New user signup with designation + department',
      fields: [
        FormFieldMeta(
          id: 'fullName',
          type: 'text',
          label: 'Full Name',
          required: true,
        ),
        FormFieldMeta(
          id: 'email',
          type: 'email',
          label: 'Email Address',
          required: true,
        ),
      ],
    );
  }
}

/* Per-field metadata */

class FormFieldMeta {
  String id;
  String type;
  String label;
  bool required;
  List<String> options;

  FormFieldMeta({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    List<String>? options,
  }) : options = options ?? [];

  factory FormFieldMeta.fromMap(Map<String, dynamic> map) {
    return FormFieldMeta(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      label: map['label'] ?? '',
      required: map['required'] ?? false,
      options: List<String>.from(map['options'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'id': id,
      'type': type,
      'label': label,
      'required': required,
    };
    if (options.isNotEmpty) {
      data['options'] = options;
    }
    return data;
  }
}
